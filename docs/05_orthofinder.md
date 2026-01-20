# Step 05: OrthoFinder - Phylogenetic Orthology Inference

## Overview

OrthoFinder is a fast, accurate phylogenomic analysis tool that identifies orthogroups (groups of genes descended from a single ancestral gene) across multiple species. It provides: 

- **Orthogroups**: Clusters of orthologous genes
- **Phylogenetic trees**: Gene and species trees
- **Gene duplication events**: Identification of paralogs
- **Comparative genomics metrics**: Ortholog statistics across species

## Why Use OrthoFinder?

- **Comparative genomics**: Understand gene family evolution
- **Core genome identification**: Find genes conserved across species
- **Species-specific expansions**: Detect lineage-specific duplications
- **Functional prediction**: Infer function via orthology transfer

## Installation

### Conda Environment

```bash
conda create -n of3 python=3.9
conda activate of3
conda install -c bioconda orthofinder
```

### Dependencies (automatically installed)

- DIAMOND or BLAST+ (sequence alignment)
- MCL (graph clustering)
- FastME (phylogenetic tree inference)
- DLCpar (optional, for gene tree reconciliation)

## Input Requirements

### Directory Structure

```
input_proteomes/
├── species1.faa
├── species2.faa
├── species3.faa
└── ...
```

### File Format

- **Extension**: `.faa`, `.fa`, or `.fasta`
- **Content**: Primary protein sequences (use output from Step 01)
- **Headers**: Simple identifiers (avoid special characters)

### Recommended Dataset Size

- **Minimum**: 3 species
- **Optimal**: 10-50 species
- **Maximum**: 1000+ species (requires significant resources)

## Running OrthoFinder

### SLURM Script

```bash
sbatch 05_run_orthofinder.sh
```

### Resource Requirements

Scales with dataset size:

| Species | CPUs | Memory | Time |
|---------|------|--------|------|
| 10 | 32 | 64 GB | 6-12 hours |
| 50 | 64 | 128 GB | 1-2 days |
| 100 | 128 | 256 GB | 3-5 days |

### Basic Command

```bash
orthofinder -f input_proteomes/ -t 32 -a 16
```

### Advanced Options

```bash
orthofinder \
  -f input_proteomes/ \
  -t 32 \
  -a 16 \
  -S diamond \
  -M msa \
  -T fasttree \
  -o output_dir \
  -n run_name
```

#### Parameter Explanations

- `-f`: Input directory containing FASTA files
- `-t`: Number of CPU threads for BLAST/DIAMOND
- `-a`: Number of threads for tree inference
- `-S`: Search program (`diamond` [fast] or `blast` [sensitive])
- `-M`: Multiple sequence alignment (`msa` or `denovo`)
- `-T`: Tree inference method (`fasttree`, `raxml`, `iqtree`)
- `-o`: Output directory
- `-n`: Run name (useful for multiple analyses)

## Output Structure

OrthoFinder creates a comprehensive results directory:

```
Results_RunName/
├── Orthogroups/
│   ├── Orthogroups.tsv              # Main orthogroup table
│   ├── Orthogroups_UnassignedGenes.tsv
│   ├── Orthogroups. GeneCount.tsv
│   └── Orthogroups_SingleCopyOrthologues.txt
│
├── Phylogenetic_Hierarchical_Orthogroups/
│   └── N0.tsv                        # Hierarchical orthogroups
│
├── Orthologues/
│   └── Orthologues_species1/
│       ├── species1__v__species2.tsv
│       └── ... 
│
├── Gene_Trees/
│   ├── OG0000001_tree.txt
│   └── ... 
│
├── Species_Tree/
│   ├── SpeciesTree_rooted.txt
│   └── SpeciesTree_rooted_node_labels.txt
│
├── Comparative_Genomics_Statistics/
│   ├── Statistics_Overall.tsv
│   ├── Statistics_PerSpecies.tsv
│   └── Duplications_per_Orthogroup.tsv
│
└── WorkingDirectory/                 # Intermediate files
```

## Key Output Files

### 1. Orthogroups. tsv

Contains all orthogroups and their member genes:

```
Orthogroup  species1  species2  species3
OG0000001   gene001, gene005  gene102  gene201, gene202
OG0000002   gene002  gene103  gene203
```

### 2. Orthogroups. GeneCount.tsv

Gene counts per species per orthogroup:

```
Orthogroup  species1  species2  species3  Total
OG0000001   2         1         2         5
OG0000002   1         1         1         3
```

### 3. SpeciesTree_rooted.txt

Phylogenetic tree in Newick format:

```
(((species1:0.05,species2:0.06):0.03,species3:0.08):0.02);
```

### 4. Statistics_Overall.tsv

Summary statistics: 

```
Number of species:  10
Number of genes: 150000
Number of orthogroups: 15000
Genes in orthogroups: 145000
Genes in single-copy orthogroups: 8000
```

### 5. Orthologues Directory

Pairwise ortholog relationships:

```
gene001 (species1) -> gene102 (species2)  [1: 1 ortholog]
gene005 (species1) -> gene102 (species2)  [many:1 ortholog]
```

## Downstream Analysis

### Find Core Orthogroups

Genes present in all species (single-copy):

```bash
grep -P "\t[^\t]+\t" Results/Orthogroups/Orthogroups_SingleCopyOrthologues. txt
```

### Identify Species-Specific Genes

```bash
awk -F'\t' '$2! ="" && $3=="" && $4=="" {print $1}' Orthogroups. tsv
```

### Count Gene Family Expansions

```bash
awk -F'\t' '{if($2>5) print $1, $2}' Orthogroups.GeneCount.tsv
```

### Visualize Species Tree

Using Python and ETE3:

```python
from ete3 import Tree, TreeStyle

t = Tree("SpeciesTree_rooted.txt")
ts = TreeStyle()
ts.show_leaf_name = True
t.render("species_tree.pdf", tree_style=ts)
```

### Extract Orthogroup Sequences

For phylogenetic analysis or gene family studies:

```bash
python extract_orthogroup_sequences.py \
  --orthogroups Orthogroups. tsv \
  --proteomes input_proteomes/ \
  --output og_sequences/
```

## Performance Optimization

### Use DIAMOND Instead of BLAST

DIAMOND is **100-1000x faster** with comparable accuracy:

```bash
orthofinder -f input/ -S diamond
```

### Pre-computed BLAST Results

If re-running with different parameters, reuse BLAST results:

```bash
orthofinder -b previous_results/WorkingDirectory/
```

### Skip Tree Inference

For quick orthogroup detection only:

```bash
orthofinder -f input/ -og
```

## Troubleshooting

### Issue: MCL inflation error

**Error**: `MCL exited with code 1`  
**Cause**: Poor quality sequences or very divergent taxa  
**Solution**: Adjust MCL inflation parameter

```bash
orthofinder -f input/ -I 1. 5  # Default is 1.5, try 2.0 or 3.0
```

### Issue: Out of memory during tree inference

**Solution**: Use less memory-intensive tree method

```bash
orthofinder -f input/ -T fasttree  # Instead of RAxML
```

### Issue: Species tree looks wrong

**Solution**: Root the tree manually using an outgroup

```bash
python scripts/root_tree.py \
  --tree SpeciesTree_unrooted.txt \
  --outgroup species_outgroup \
  --output SpeciesTree_rooted.txt
```

### Issue: Too many unassigned genes

**Possible causes**:
- Sequences too short (< 50 aa)
- Poor sequence quality
- Highly divergent species

**Solution**: Filter input sequences by length

```bash
seqkit seq -m 50 input.faa > filtered.faa
```

## Quality Control

### Check Orthogroup Size Distribution

```bash
awk -F'\t' '{print NF-1}' Orthogroups.tsv | sort -n | uniq -c
```

**Expected**: Most orthogroups have 3-20 genes. 

### Validate Species Tree

Compare with published phylogenies:

```bash
# Use TreeCmp or other tree comparison tools
treecmp -r reference_tree.nwk -i SpeciesTree_rooted.txt
```

### Assess Single-Copy Orthologs

High-quality datasets have **>5%** single-copy orthologs: 

```bash
wc -l Orthogroups_SingleCopyOrthologues. txt
```

## Integration with Other Steps

### Use for Functional Annotation Transfer

```python
# Transfer KO assignments via orthology
for og in orthogroups:
    if any_member_has_KO(og):
        assign_KO_to_all_members(og)
```

### Phylogenetic Profiling

Identify genes with unusual phylogenetic distributions:

```R
library(pheatmap)

gene_count <- read.csv("Orthogroups.GeneCount.tsv", sep="\t")
pheatmap(gene_count[,-1], cluster_rows=TRUE, cluster_cols=TRUE)
```

### Combine with Synteny Analysis

OrthoFinder orthologs can seed synteny detection tools like MCScanX. 

## Publications Using OrthoFinder

- **Emms & Kelly (2019)** Genome Biology - Original OrthoFinder2 paper
- **Emms & Kelly (2015)** Genome Biology - OrthoFinder1 paper
- Cited in **>5,000 publications** (as of 2026)

## Citation

```
Emms, D.M.  and Kelly, S.  (2019) OrthoFinder: phylogenetic orthology 
inference for comparative genomics.  Genome Biology 20:238
```

---

**Script**:  `scripts/05_run_orthofinder.sh`  
**Expected Runtime**: 6 hours - 5 days (dataset-dependent)  
**Memory**:  64-256 GB  
**CPU**: 32-128 cores
