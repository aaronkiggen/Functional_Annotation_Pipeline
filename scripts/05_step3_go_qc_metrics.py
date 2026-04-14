#!/usr/bin/env python3
# ==============================================================================
# Script: 05_step3_go_qc_metrics.py
# Description: Compares GO terms predicted by FANTASIA with standard tools
#              (EggNOG/InterProScan) using Wang's Semantic Similarity to
#              account for GO Graph topological depth (parent/child relations).
# ==============================================================================

import pandas as pd
import argparse
import os
import urllib.request
import math

# ------------------------------------------------------------------------------
# 1. OBO Parser & Wang Semantic Similarity (Wang et al. 2007)
# ------------------------------------------------------------------------------

def download_obo(file_path="go-basic.obo"):
    url = "http://purl.obolibrary.org/obo/go/go-basic.obo"
    if not os.path.exists(file_path):
        print(f"Downloading {url}...")
        urllib.request.urlretrieve(url, file_path)
    return file_path

def parse_obo(obo_file):
    print("Parsing go-basic.obo...")
    terms = {}
    current_term = None
    with open(obo_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line == '[Term]':
                current_term = {'id': '', 'is_a': [], 'part_of': []}
            elif line.startswith('id: ') and current_term is not None:
                current_term['id'] = line.split('id: ')[1].strip()
                terms[current_term['id']] = current_term
            elif line.startswith('is_a: ') and current_term is not None:
                target = line.split('is_a: ')[1].split('!')[0].strip()
                current_term['is_a'].append(target)
            elif line.startswith('relationship: part_of ') and current_term is not None:
                target = line.split('relationship: part_of ')[1].split('!')[0].strip()
                current_term['part_of'].append(target)
    return terms

def compute_semantic_values(term_id, terms, w_isa=0.8, w_partof=0.6):
    """
    Computes Semantic Value S_A(t) for a term and all its ancestors.
    Uses a priority queue approach to propagate the max semantic value.
    """
    if term_id not in terms:
        return {}
    
    S = {term_id: 1.0}
    queue = [term_id]
    
    while queue:
        curr = queue.pop(0)
        curr_val = S[curr]
        
        if curr not in terms:
            continue
            
        # Top-down propagation for 'is_a'
        for parent in terms[curr]['is_a']:
            new_val = curr_val * w_isa
            if parent not in S or new_val > S[parent]:
                S[parent] = new_val
                queue.append(parent)
                
        # Top-down propagation for 'part_of'
        for parent in terms[curr]['part_of']:
            new_val = curr_val * w_partof
            if parent not in S or new_val > S[parent]:
                S[parent] = new_val
                queue.append(parent)
                
    return S

def wang_sim(goA, goB, terms, cache):
    """Wang similarity between two individual GO terms."""
    if goA == goB:
        return 1.0
        
    if goA not in cache:
        cache[goA] = compute_semantic_values(goA, terms)
    if goB not in cache:
        cache[goB] = compute_semantic_values(goB, terms)
        
    SA = cache[goA]
    SB = cache[goB]
    
    intersect = set(SA.keys()).intersection(set(SB.keys()))
    if not intersect:
        return 0.0
        
    sum_intersect = sum(SA[t] + SB[t] for t in intersect)
    svA = sum(SA.values())
    svB = sum(SB.values())
    
    return sum_intersect / (svA + svB) if (svA + svB) > 0 else 0.0

def bma_wang_sim(set1, set2, terms, cache):
    """
    Best-Match Average (BMA) Wang similarity between two SETS of GO terms.
    Accounts for lists of multiple GO terms assigned to a single protein.
    """
    if not set1 and not set2:
        return 0.0
    if not set1 or not set2:
        return 0.0

    sum1 = 0.0
    for go1 in set1:
        if go1 not in terms: continue
        max_sim = max([wang_sim(go1, go2, terms, cache) for go2 in set2 if go2 in terms], default=0.0)
        sum1 += max_sim
        
    sum2 = 0.0
    for go2 in set2:
        if go2 not in terms: continue
        max_sim = max([wang_sim(go1, go2, terms, cache) for go1 in set1 if go1 in terms], default=0.0)
        sum2 += max_sim
        
    valid_len1 = len([g for g in set1 if g in terms])
    valid_len2 = len([g for g in set2 if g in terms])
    
    if valid_len1 + valid_len2 == 0:
        return 0.0
        
    return (sum1 + sum2) / (valid_len1 + valid_len2)

# ------------------------------------------------------------------------------
# 2. File Parsers
# ------------------------------------------------------------------------------

def parse_fantasia_gff(gff_file):
    go_dict = {}
    if not os.path.exists(gff_file): return go_dict
    with open(gff_file, 'r') as f:
        for line in f:
            if line.startswith('#'): continue
            parts = line.strip().split('\t')
            if len(parts) < 9 or parts[2] != 'mRNA': continue
            
            attr_part = parts[8]
            t_id = None
            go_terms = set()
            
            for attr in attr_part.split(';'):
                if attr.startswith('ID='): t_id = attr.split('=')[1]
                elif attr.startswith('Ontology_term='):
                    terms = attr.split('=')[1].split(',')
                    go_terms.update([t.strip() for t in terms if t.startswith('GO:')])
                    
            if t_id and go_terms:
                go_dict[t_id] = go_terms
    return go_dict

def parse_eggnog(eggnog_file):
    go_dict = {}
    if not os.path.exists(eggnog_file): return go_dict
    with open(eggnog_file, 'r') as f:
        for line in f:
            if line.startswith('#'): continue
            parts = line.strip().split('\t')
            if len(parts) >= 10:
                t_id = parts[0]
                go_str = parts[9]
                if go_str and go_str != '-':
                    go_dict[t_id] = set(go_str.split(','))
    return go_dict

def parse_interproscan(ips_file):
    go_dict = {}
    if not os.path.exists(ips_file): return go_dict
    with open(ips_file, 'r') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 14:
                t_id = parts[0]
                go_str = parts[13]
                if go_str.startswith('GO:'):
                    if t_id not in go_dict: go_dict[t_id] = set()
                    go_dict[t_id].update(go_str.split('|'))
    return go_dict

def calculate_exact_metrics(gold_standard, prediction):
    if not gold_standard or not prediction: return 0.0, 0.0, 0.0, 0.0
    true_positives = len(gold_standard.intersection(prediction))
    precision = true_positives / len(prediction)
    recall = true_positives / len(gold_standard)
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0
    jaccard = true_positives / len(gold_standard.union(prediction))
    return precision, recall, f1, jaccard

# ------------------------------------------------------------------------------
# 3. Main
# ------------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="QC GO terms using Topological Wang Similarity.")
    parser.add_argument('--fantasia_gff', required=True, help="BRAKER4 GFF file containing Fantasia Output.")
    parser.add_argument('--eggnog', required=True, help="EggNOG annotation (.emapper.annotations).")
    parser.add_argument('--ips', required=True, help="InterProScan TSV output.")
    parser.add_argument('--output', required=True, help="Output Excel metrics file.")
    args = parser.parse_args()

    # Automatically fetch latest gene ontology DAG hierarchy
    obo_path = download_obo("go-basic.obo")
    onto_terms = parse_obo(obo_path)
    semantic_cache = {}

    print("Parsing FANTASIA GO terms (from GFF)...")
    fan_dict = parse_fantasia_gff(args.fantasia_gff)
    
    print("Parsing EggNOG GO terms...")
    egg_dict = parse_eggnog(args.eggnog)
    
    print("Parsing InterProScan GO terms...")
    ips_dict = parse_interproscan(args.ips)
    
    all_proteins = set(fan_dict.keys()).union(egg_dict.keys()).union(ips_dict.keys())
    
    print("Calculating Exact & Wang Semantic Similarities...")
    results = []
    
    # Track statistics for the summary printout
    total_valid = 0
    total_f1 = 0.0
    total_wang = 0.0
    
    for count, t_id in enumerate(list(all_proteins)):
        if count > 0 and count % 5000 == 0:
            print(f"Processed {count}/{len(all_proteins)} proteins...")
            
        standard_go = set()
        standard_go.update(egg_dict.get(t_id, set()))
        standard_go.update(ips_dict.get(t_id, set()))
        
        fan_go = fan_dict.get(t_id, set())
        
        # Only process genes where BOTH FANTASIA and standard tools found GO terms
        if len(standard_go) == 0 and len(fan_go) == 0:
            continue
            
        # Exact matching metrics (Strict Intersection)
        p, r, f1, jacc = calculate_exact_metrics(standard_go, fan_go)
        
        # Wang semantic similarity metrics (Graph-aware Best Match Avg)
        wang_bma = bma_wang_sim(standard_go, fan_go, onto_terms, semantic_cache)
            
        
        results.append({
            'Protein_ID': t_id,
            'GoldStandard_Count': len(standard_go),
            'Fantasia_Count': len(fan_go),
            'Exact_F1': round(f1, 4),
            'Wang_Semantic_Sim (BMA)': round(wang_bma, 4)
        })
        
        total_valid += 1
        total_f1 += f1
        total_wang += wang_bma
        
    df = pd.DataFrame(results)
    
    if df.empty or total_valid == 0:
        print("Warning: No matching GO terms found to compare.")
    else:
        avg_f1 = total_f1 / total_valid
        avg_wang = total_wang / total_valid
        
        print("\n===============================")
        print("          QC SUMMARY           ")
        print("===============================")
        print(f"Proteins Compared:           {total_valid}")
        print(f"Average Exact F1 (Strict):   {avg_f1:.3f}")
        print(f"Average Wang Semantic Sim:   {avg_wang:.3f}")
        print("===============================\n")
        
    print(f"Saving per-protein Semantic Similarity table to {args.output}...")
    df.to_excel(args.output, index=False)

if __name__ == "__main__":
    main()
