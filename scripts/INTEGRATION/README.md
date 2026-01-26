# Integration Scripts

This directory contains scripts for integrating and formatting outputs from the functional annotation pipeline.

## Scripts

### create_excel_outputs.py

A Python script that parses output files from functional annotation tools and generates Excel files with standardized format. For each tool, the script generates two types of outputs:

1. **Per-term output**: One row per functional term (GO or KEGG)
2. **Per-gene output**: One row per gene with functional terms grouped together in one cell

#### Output Formats by Tool

##### KofamScan
- **Per-term output** (`*_kofamscan_per_term.xlsx`):
  - Columns: `gene_name`, `KEGG`
  - One row per KEGG term (or gene without KEGG term)
- **Per-gene output** (`*_kofamscan_per_gene.xlsx`):
  - Columns: `gene_name`, `KEGG`
  - One row per gene with KEGG terms grouped (comma-separated)

##### InterProScan
- **Per-term output** (`*_interproscan_per_term.xlsx`):
  - Columns: `gene`, `analysis`, `score`, `InterPro_accession`, `InterPro_description`, `GO`, `Pathways`
  - One row per hit in the database
- **Per-gene output** (`*_interproscan_per_gene.xlsx`):
  - Columns: `gene`, `GO`, `Pathways`
  - One row per gene with GO terms and pathways grouped

##### EggNOG-mapper
- **Per-gene output** (`*_eggnog_v[5|7]_per_gene.xlsx`):
  - Columns: `gene`, `Description`, `GOs`, `KEGG_ko`, `KEGG_Pathway`, `KEGG_Reaction`, `KEGG_rclass`, `PFAM`
  - One row per gene (already the desired format)
- **Per-term output** (`*_eggnog_v[5|7]_per_term.xlsx`):
  - Columns: `gene`, `term_type`, `term`
  - One row per GO or KEGG term

##### FANTASIA
- **Per-term output** (`*_fantasia_{model}_per_term.xlsx`):
  - Columns: `gene`, `GO`, `term_count`, `final_score`
  - One row per GO term
  - Separate file for each model (ESM-2, ProtT5, ProstT5, Ankh3-Large, ESM3c)
- **Per-gene output** (`*_fantasia_{model}_per_gene.xlsx`):
  - Columns: `gene`, `GO`
  - One row per gene with GO terms grouped (comma-separated)
  - Separate file for each model

**Note**: OrthoFinder outputs are excluded as per requirements.

#### Supported Tools

The script processes outputs from:

1. **KofamScan** - KEGG Orthology annotation
   - Input: `*_kofam_mapper.tsv` files
   - Functional terms: KEGG KO identifiers (e.g., K00001)

2. **InterProScan** - Domain and motif analysis
   - Input: `*.tsv` files
   - Functional terms: GO terms and pathways

3. **EggNOG-mapper** - Orthology and functional annotation
   - Input: `.emapper.annotations` files (v5) and `.eggnog.tsv.gz` files (v7)
   - Functional terms: GO terms and KEGG KO identifiers
   - Note: Properly handles comment lines (including first 2 rows with ##)

4. **FANTASIA** - AI-driven functional annotation
   - Input: `*.tsv` files from FANTASIA output directory
   - Functional terms: GO terms
   - Output: One Excel file per model (ESM-2, ProtT5, ProstT5, Ankh3-Large, ESM3c)

#### Installation

Install required Python packages:

```bash
pip install pandas openpyxl
```

Or using conda:

```bash
conda install -c conda-forge pandas openpyxl
```

#### Usage

##### Basic Usage

Process all annotation results in default directories:

```bash
cd scripts/INTEGRATION
python create_excel_outputs.py
```

This will:
- Look for results in `../../results/` directory
- Create Excel files in `./excel_outputs/` directory

##### Custom Directories

Specify custom input and output directories:

```bash
python create_excel_outputs.py -r /path/to/results -o /path/to/output
```

##### Process Specific Tools

Process only specific tool outputs:

```bash
# KofamScan only
python create_excel_outputs.py --kofamscan-only

# InterProScan only
python create_excel_outputs.py --interproscan-only

# EggNOG-mapper only
python create_excel_outputs.py --eggnog-only

# FANTASIA only
python create_excel_outputs.py --fantasia-only
```

#### Command-Line Options

```
usage: create_excel_outputs.py [-h] [-r RESULTS_DIR] [-o OUTPUT_DIR]
                                [--kofamscan-only] [--interproscan-only]
                                [--eggnog-only] [--fantasia-only]

Generate Excel files from functional annotation outputs

optional arguments:
  -h, --help            show this help message and exit
  -r RESULTS_DIR, --results-dir RESULTS_DIR
                        Results directory containing tool outputs (default: ../../results)
  -o OUTPUT_DIR, --output-dir OUTPUT_DIR
                        Output directory for Excel files (default: ./excel_outputs)
  --kofamscan-only      Process only KofamScan results
  --interproscan-only   Process only InterProScan results
  --eggnog-only         Process only EggNOG-mapper results
  --fantasia-only       Process only FANTASIA results
```

#### Output Files

The script generates two Excel files per input sample and tool (per-term and per-gene):

**KofamScan:**
- `{sample}_kofamscan_per_term.xlsx` - One row per KEGG term
- `{sample}_kofamscan_per_gene.xlsx` - One row per gene with grouped KEGG

**InterProScan:**
- `{sample}_interproscan_per_term.xlsx` - One row per hit
- `{sample}_interproscan_per_gene.xlsx` - One row per gene with grouped GO/Pathways

**EggNOG-mapper:**
- `{sample}_eggnog_v5_per_gene.xlsx` - One row per gene (v5)
- `{sample}_eggnog_v5_per_term.xlsx` - One row per GO/KEGG term (v5)
- `{sample}_eggnog_v7_per_gene.xlsx` - One row per gene (v7)
- `{sample}_eggnog_v7_per_term.xlsx` - One row per GO/KEGG term (v7)

**FANTASIA:**
- `{sample}_fantasia_{model}_per_term.xlsx` - One row per GO term (per model)
- `{sample}_fantasia_{model}_per_gene.xlsx` - One row per gene with grouped GO (per model)

Each Excel file includes:
- Formatted headers (blue background, white text)
- Auto-sized columns for readability
- All annotations for the sample

#### Example Outputs

**KofamScan Per-Term:**
| gene_name | KEGG |
|-----------|------|
| KAK4002030.1 | |
| KAK4001898.1 | K20050 |
| KAK4001899.1 | K16759 |

**InterProScan Per-Term:**
| gene | analysis | score | InterPro_accession | InterPro_description | GO | Pathways |
|------|----------|-------|-------------------|---------------------|-----|----------|
| P51587 | Pfam | 3.1E-52 | IPR002093 | BRCA2 repeat | GO:0005515\|GO:0006302 | REACT_71 |

**EggNOG Per-Gene:**
| gene | Description | GOs | KEGG_ko | KEGG_Pathway | KEGG_Reaction | KEGG_rclass | PFAM |
|------|-------------|-----|---------|--------------|---------------|-------------|------|
| KAK4001897.1 | Belongs to the ubiquitin-conjugating enzyme family | GO:0000151,GO:0003674,... | ko:K00001,ko:K00002 | map00010,map00020 | R00001 | RC00001 | F-box-like,UQ_con |

**FANTASIA Per-Term:**
| gene | GO | term_count | final_score |
|------|-----|-----------|-------------|
| KAK4001897.1 | GO:0000151 | 5 | 0.85 |
| KAK4001897.1 | GO:0003674 | 3 | 0.80 |

#### Integration with Pipeline

This script is designed to be run after annotation steps (Steps 02-06) of the pipeline:

```bash
# Run annotation steps
sbatch 02_run_kofamscan.sh
sbatch 03_run_interproscan.sh
sbatch 04_1_run_eggnog_V5.sh
sbatch 04_2_run_eggnog7_annotator.sh
sbatch 05_run_orthofinder.sh  # Optional - not included in Excel outputs
sbatch 06_run_fantasia.slurm

# Wait for jobs to complete, then generate Excel outputs
cd scripts/INTEGRATION
python create_excel_outputs.py
```

#### Troubleshooting

**Error: Required packages not found**
- Install pandas and openpyxl: `pip install pandas openpyxl`

**Warning: No files found**
- Check that the results directory path is correct
- Ensure annotation steps have completed successfully
- Verify output file naming conventions match expectations

**Empty Excel files**
- Check that input files contain data (not just headers)
- Verify file formats match expected patterns

#### Future Enhancements

Potential improvements for this script:
- [ ] Merge multiple tools' annotations for the same gene into a single Excel file
- [ ] Add summary statistics sheet (e.g., annotation coverage per tool)
- [ ] Filter by confidence scores or E-values
- [ ] Generate combined annotation report with all tools
