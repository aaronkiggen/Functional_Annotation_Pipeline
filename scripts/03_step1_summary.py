#!/usr/bin/env python3
# ==============================================================================
# Script: 03_step1_summary.py
# Description: Parses BRAKER4 GTF/GFFs and OrthoFinder Statistics to generate
#              comparative genomic statistics (genes per species, orthologs, etc.)
# ==============================================================================

import os
import sys
import pandas as pd
import glob
from collections import defaultdict
import argparse

def parse_gff(gff_file):
    """Parse a GFF3 file to count genes, mRNAs, and calculate basic stats."""
    stats = {'genes': 0, 'mRNAs': 0, 'exons': 0}
    if not os.path.exists(gff_file):
        return stats
        
    with open(gff_file, 'r') as f:
        for line in f:
            if line.startswith('#'):
                continue
            parts = line.strip().split('\t')
            if len(parts) < 3:
                continue
            
            feature_type = parts[2]
            if feature_type == 'gene':
                stats['genes'] += 1
            elif feature_type == 'mRNA' or feature_type == 'transcript':
                stats['mRNAs'] += 1
            elif feature_type == 'exon':
                stats['exons'] += 1
                
    return stats

def main():
    parser = argparse.ArgumentParser(description="Generate summary statistics for BRAKER4 and OrthoFinder.")
    parser.add_argument('--braker_dir', required=True, help="Directory containing BRAKER4 output sample folders.")
    parser.add_argument('--orthofinder_dir', required=True, help="Directory of the OrthoFinder results containing 'Statistics_Overall.tsv'.")
    parser.add_argument('--output', required=True, help="Output Excel file path.")
    
    args = parser.parse_args()
    
    print("========================================")
    print("      Step 1: BRAKER4 & OrthoFinder QC  ")
    print("========================================")
    
    # 1. Parse BRAKER4 GFFs
    print(f"Parsing BRAKER4 outputs from {args.braker_dir}...")
    sample_stats = []
    
    # BRAKER4 output structure: braker_dir/output/sample_name/braker.gff3
    braker_output = os.path.join(args.braker_dir, 'output')
    subdirs = []
    if os.path.exists(braker_output):
        subdirs = [d for d in os.listdir(braker_output) if os.path.isdir(os.path.join(braker_output, d))]
    else:
        print(f"Warning: {braker_output} not found")
        
    for sample in subdirs:
        gff_path = os.path.join(braker_output, sample, "braker.gff3")
        if os.path.exists(gff_path):
            stats = parse_gff(gff_path)
            stats['Sample'] = sample
            
            # Extract species/mode assumption from sample name if it follows format 'species_mode'
            parts = sample.split('_')
            stats['Species'] = parts[0] if len(parts) > 0 else sample
            stats['Mode'] = parts[1] if len(parts) > 1 else 'Unknown'
            
            sample_stats.append(stats)
        else:
            print(f"Warning: No braker.gff3 found for {sample}")

    df_braker = pd.DataFrame(sample_stats)
    
    # 2. Parse OrthoFinder Statistics
    print(f"Parsing OrthoFinder statistics from {args.orthofinder_dir}...")
    of_stats_file = os.path.join(args.orthofinder_dir, "Comparative_Genomics_Statistics", "Statistics_Overall.tsv")
    of_species_file = os.path.join(args.orthofinder_dir, "Comparative_Genomics_Statistics", "Statistics_PerSpecies.tsv")
    
    of_data = {}
    if os.path.exists(of_stats_file):
        df_overall = pd.read_csv(of_stats_file, sep='\t')
        of_data['Overall_Statistics'] = df_overall
    else:
        print(f"Warning: {of_stats_file} not found.")
        
    if os.path.exists(of_species_file):
        df_species = pd.read_csv(of_species_file, sep='\t')
        of_data['Species_Statistics'] = df_species
    else:
        print(f"Warning: {of_species_file} not found.")

    # 3. Save to Excel
    print(f"Saving combined statistics to {args.output}...")
    with pd.ExcelWriter(args.output) as writer:
        if not df_braker.empty:
            df_braker.to_excel(writer, sheet_name='BRAKER4_Gene_Stats', index=False)
        if 'Overall_Statistics' in of_data:
            of_data['Overall_Statistics'].to_excel(writer, sheet_name='OrthoFinder_Overall', index=False)
        if 'Species_Statistics' in of_data:
            of_data['Species_Statistics'].to_excel(writer, sheet_name='OrthoFinder_PerSpecies', index=False)
            
    print("Done!")

if __name__ == "__main__":
    main()
