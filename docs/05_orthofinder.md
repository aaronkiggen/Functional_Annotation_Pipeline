# Step 05: OrthoFinder - Phylogenetic Orthology

Identifies orthogroups (genes from a common ancestor) and constructs phylogenetic trees across multiple species.

## Installation

```bash
conda create -n of3 python=3.9
conda activate of3
conda install -c bioconda orthofinder
```

## Input

Place protein FASTA files in a directory (use output from Step 01):
```
input_proteomes/
├── species1.faa
├── species2.faa
└── species3.faa
```

**Recommended**: 10-50 species for optimal results

## Usage

```bash
sbatch 05_run_orthofinder.sh
```

### Basic Command
```bash
orthofinder -f input_proteomes/ -t 32 -a 16
```

### Advanced Options
```bash
orthofinder -f input_proteomes/ -t 32 -a 16 \
  -S diamond \      # Fast search (vs. blast)
  -M msa \          # Multiple sequence alignment
  -o output_dir \
  -n run_name
```

## Resource Requirements

| Species | CPUs | Memory | Time |
|---------|------|--------|------|
| 10 | 32 | 64 GB | 6-12 hours |
| 50 | 64 | 128 GB | 1-2 days |
| 100 | 128 | 256 GB | 3-5 days |

## Key Output Files

### Orthogroups.tsv
Gene clusters per species:
```
Orthogroup  species1        species2  species3
OG0000001   gene001,gene005 gene102   gene201,gene202
```

### Orthogroups.GeneCount.tsv
Gene counts per orthogroup:
```
Orthogroup  species1  species2  species3  Total
OG0000001   2         1         2         5
```

### SpeciesTree_rooted.txt
Phylogenetic tree (Newick format)

### Statistics_Overall.tsv
Summary statistics including number of orthogroups and single-copy genes

## Common Tasks

### Find Core Orthogroups (single-copy in all species)
```bash
cat Orthogroups_SingleCopyOrthologues.txt
```

### Count Gene Family Expansions
```bash
awk -F'\t' '{if($2>5) print $1, $2}' Orthogroups.GeneCount.tsv
```

### Visualize Species Tree
```python
from ete3 import Tree, TreeStyle
t = Tree("SpeciesTree_rooted.txt")
t.render("species_tree.pdf")
```

## Performance Tips

- **Use DIAMOND**: 100-1000x faster than BLAST (`-S diamond`)
- **Reuse results**: Use `-b previous_results/WorkingDirectory/` to rerun with different parameters
- **Quick mode**: Use `-og` to skip tree inference

## Troubleshooting

**MCL inflation error**: Adjust parameter `-I 2.0` (default: 1.5)

**Out of memory**: Use FastTree instead of RAxML (`-T fasttree`)

**Too many unassigned genes**: Filter short sequences (<50 aa) with `seqkit seq -m 50`

**Expected**: >5% single-copy orthologs indicates high-quality dataset
