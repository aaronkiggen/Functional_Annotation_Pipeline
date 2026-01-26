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

### filter_fantasia_results.py

A Python script that performs post-processing filtering on FANTASIA results using 25th percentile (Q1) thresholds. The script filters both individual model Excel files and creates a consensus result across all models.

#### Features

1. **Calculate Model-Specific Thresholds**: Computes 25th percentile (Q1) for each model from non-zero scores
2. **Task A - Filter Individual Excel Files**: Filters each model's Excel file based on its specific threshold
3. **Task B - Consensus Filtering**: Creates a consensus result requiring majority vote (≥3 out of 5 models)
4. **Gene Mapping**: Optional protein-to-gene mapping from FASTA file

#### Installation

The script uses the same dependencies as `create_excel_outputs.py`:

```bash
pip install pandas openpyxl
```

#### Usage

##### Basic Usage

Filter FANTASIA results with default output to Excel directory:

```bash
python filter_fantasia_results.py \
  --summary results/fantasia/sample.tsv \
  --excel-dir excel_outputs/
```

##### With Custom Output Directory

Specify a separate directory for filtered outputs:

```bash
python filter_fantasia_results.py \
  --summary results/fantasia/sample.tsv \
  --excel-dir excel_outputs/ \
  --output-dir filtered_results/
```

##### With Gene Mapping

Include protein-to-gene mapping from FASTA file:

```bash
python filter_fantasia_results.py \
  --summary results/fantasia/sample.tsv \
  --excel-dir excel_outputs/ \
  --fasta proteins/sample.faa
```

#### Command-Line Options

```
usage: filter_fantasia_results.py [-h] --summary SUMMARY --excel-dir EXCEL_DIR 
                                  [--fasta FASTA] [--output-dir OUTPUT_DIR]

Filter FANTASIA results using 25th percentile thresholds

required arguments:
  --summary SUMMARY     Path to FANTASIA summary CSV/TSV file
  --excel-dir EXCEL_DIR Directory containing Excel files generated by create_excel_outputs.py

optional arguments:
  --fasta FASTA         Path to protein FASTA file (optional, for gene mapping)
  --output-dir OUTPUT_DIR
                        Directory to save filtered outputs (default: same as excel-dir)
```

#### Output Files

The script generates the following outputs:

**Task A - Filtered Individual Excel Files:**
- `{sample}_fantasia_{model}_per_term_filtered.xlsx` - One file per model with entries passing that model's Q1 threshold
- Only includes rows where `final_score >= Q1_threshold` for that specific model

**Task B - Consensus Results:**
- `fantasia_consensus_majority.csv` - CSV file with entries passing majority vote (≥3/5 models)
- `fantasia_consensus_majority.xlsx` - Excel file with same data, formatted
- Includes `consensus_vote` column showing how many models passed threshold
- If FASTA provided, includes `gene_id` column with protein-to-gene mapping

#### Threshold Calculation

For each model column (e.g., `final_score_ESM_L0`, `final_score_Prot-T5_L0`, etc.):
1. Extract all non-zero scores
2. Calculate 25th percentile (Q1)
3. Use Q1 as the minimum threshold (keeps top 75% of non-zero scores)

#### Model Name Mapping

The script automatically maps between Excel file names and CSV column names:

| Excel Model Name | CSV Column Suffix |
|-----------------|-------------------|
| ESM-2           | ESM_L0           |
| ProtT5          | Prot-T5_L0       |
| ProstT5         | Prost-T5_L0      |
| Ankh3-Large     | Ankh3-Large_L0   |
| ESM3c           | ESM3c_L0         |

#### Example Workflow

```bash
# Step 1: Generate Excel files from FANTASIA results
python create_excel_outputs.py --fantasia-only

# Step 2: Filter FANTASIA results
python filter_fantasia_results.py \
  --summary ../../results/fantasia/sample_fantasia.tsv \
  --excel-dir ./excel_outputs/ \
  --fasta ../../proteins/sample.faa \
  --output-dir ./filtered_fantasia/

# Results:
# - Individual filtered Excel files for each model
# - Consensus file with entries passing ≥3 models
# - Gene IDs mapped from FASTA
```

#### Integration with Pipeline

Run this script after `create_excel_outputs.py` to perform quality filtering:

```bash
cd scripts/INTEGRATION

# Generate Excel outputs
python create_excel_outputs.py --fantasia-only

# Filter results
python filter_fantasia_results.py \
  --summary ../../results/fantasia/sample.tsv \
  --excel-dir excel_outputs/
```

#### Troubleshooting

**Error: No thresholds calculated**
- Verify summary file has `final_score_*_L0` columns
- Check that scores are numeric and non-zero values exist

**Warning: Could not determine model for file**
- Ensure Excel files follow naming pattern: `*_fantasia_{model}_per_term.xlsx`
- Model name must be one of: ESM-2, ProtT5, ProstT5, Ankh3-Large, ESM3c

**Gene mapping not working**
- Check FASTA file exists and is readable
- Verify FASTA headers contain `gene=` tags
- If no `gene=` tag, protein ID will be used as gene ID

#### Future Enhancements

Potential improvements for this script:
- [ ] Merge multiple tools' annotations for the same gene into a single Excel file
- [ ] Add summary statistics sheet (e.g., annotation coverage per tool)
- [ ] Filter by confidence scores or E-values
- [ ] Generate combined annotation report with all tools

### analyze_annotation_results.py

A Python script that analyzes and visualizes annotation results before integration. It provides comprehensive statistics on gene coverage, annotation percentages per tool, and overlap analysis between different annotation tools.

#### Features

1. **Gene Counting**: Count total genes from protein FASTA file
2. **Per-Tool Statistics**: Count annotated genes for each tool (KofamScan, InterProScan, EggNOG, FANTASIA)
3. **Separate GO/KEGG Counts**: For EggNOG, provides separate counts for GO and KEGG annotations
4. **Pre/Post-Filtering Analysis**: For FANTASIA, analyzes both unfiltered and filtered results
5. **Visualization**: Generate pie charts and bar charts showing annotation percentages
6. **Overlap Analysis**: Calculate overlaps between tools and identify unique annotations
7. **FANTASIA Unique Contributions**: Identify genes uniquely annotated by FANTASIA

#### Installation

The script requires the same dependencies as `create_excel_outputs.py`, plus matplotlib for visualization:

```bash
pip install pandas matplotlib openpyxl
```

Or using conda:

```bash
conda install -c conda-forge pandas matplotlib openpyxl
```

#### Usage

##### Basic Usage

Analyze annotation results for a sample:

```bash
python analyze_annotation_results.py \
  --fasta proteins/sample.faa \
  --excel-dir excel_outputs/ \
  --sample sample
```

This will:
- Count total genes from the FASTA file
- Analyze all per-gene Excel files matching the sample prefix
- Generate summary statistics and visualizations
- Save outputs to the current directory

##### With Custom Output Directory

Specify a custom directory for analysis outputs:

```bash
python analyze_annotation_results.py \
  --fasta proteins/sample.faa \
  --excel-dir excel_outputs/ \
  --sample sample \
  --output-dir analysis_results/
```

#### Command-Line Options

```
usage: analyze_annotation_results.py [-h] --fasta FASTA --excel-dir EXCEL_DIR
                                      --sample SAMPLE [--output-dir OUTPUT_DIR]

Analyze and visualize annotation results before integration

required arguments:
  --fasta FASTA         Path to protein FASTA file
  --excel-dir EXCEL_DIR Directory containing Excel files generated by create_excel_outputs.py
  --sample SAMPLE       Sample name prefix for file matching (e.g., "mysample" for 
                        mysample_kofamscan_per_gene.xlsx)

optional arguments:
  --output-dir OUTPUT_DIR
                        Directory to save analysis outputs (default: current directory)
```

#### Input Files

The script expects the following per-gene Excel files in the `--excel-dir` directory:

**Required Files:**
- `{sample}_kofamscan_per_gene.xlsx` - KofamScan annotations
- `{sample}_interproscan_per_gene.xlsx` - InterProScan annotations
- `{sample}_eggnog_v5_per_gene.xlsx` or `{sample}_eggnog_v7_per_gene.xlsx` - EggNOG annotations

**Optional Files (for FANTASIA analysis):**
- `{sample}_fantasia_{model}_per_gene.xlsx` - Unfiltered FANTASIA results (per model)
- `{sample}_fantasia_{model}_per_gene_filtered.xlsx` - Filtered FANTASIA results (per model)

Where `{model}` is one of: ESM-2, ProtT5, ProstT5, Ankh3-Large, ESM3c

#### Output Files

The script generates four output files:

1. **`{sample}_annotation_summary.csv`**
   - CSV table with annotation statistics for each tool
   - Columns: Tool, Annotated Genes, Total Genes, Percentage, Percentage_Value
   - Separate rows for EggNOG GO and KEGG annotations
   - Separate rows for FANTASIA pre- and post-filtering (per model)

2. **`{sample}_annotation_pie_charts.png`**
   - Grid of pie charts, one per tool/annotation type
   - Shows annotated vs unannotated genes as percentages
   - Visual representation of annotation coverage

3. **`{sample}_annotation_comparison.png`**
   - Bar chart comparing annotation percentages across all tools
   - Useful for quick comparison of tool effectiveness
   - Includes percentage labels on each bar

4. **`{sample}_overlap_summary.txt`**
   - Text file with detailed overlap analysis
   - Statistics on genes annotated by multiple tools
   - KofamScan + InterProScan + EggNOG combined and overlap
   - FANTASIA unique contributions (genes not in other tools)
   - Example gene IDs for FANTASIA-unique annotations

#### Analysis Details

##### Tool-Specific Counting

**KofamScan**: Counts genes with non-empty KEGG annotations in the `KEGG` column

**InterProScan**: Counts genes with non-empty GO terms or Pathways in respective columns

**EggNOG**: 
- GO count: Genes with non-empty `GOs` column
- KEGG count: Genes with non-empty `KEGG_ko` column
- Combined: Union of genes with either GO or KEGG annotations

**FANTASIA**:
- Pre-filtering: Counts from unfiltered per-gene files
- Post-filtering: Counts from filtered per-gene files (if available)
- Reports separate statistics for each of the 5 models

##### Overlap Calculations

The script calculates several overlap metrics:

1. **All tools combined**: Union of genes annotated by any tool
2. **Annotated by all tools**: Intersection of genes annotated by every tool
3. **KofamScan + InterProScan + EggNOG combined**: Union of these three tools
4. **KofamScan + InterProScan + EggNOG overlap**: Intersection of these three tools
5. **FANTASIA unique**: Genes in FANTASIA (post-filtering) but not in the three main tools

#### Example Workflow

Complete workflow from raw results to analysis:

```bash
cd scripts/INTEGRATION

# Step 1: Generate Excel outputs from annotation results
python create_excel_outputs.py \
  --results-dir ../../results/ \
  --output-dir excel_outputs/

# Step 2: Filter FANTASIA results (optional but recommended)
python filter_fantasia_results.py \
  --summary ../../results/fantasia/sample.tsv \
  --excel-dir excel_outputs/ \
  --fasta ../../proteins/sample.faa

# Step 3: Analyze and visualize annotation results
python analyze_annotation_results.py \
  --fasta ../../proteins/sample.faa \
  --excel-dir excel_outputs/ \
  --sample sample \
  --output-dir analysis_results/
```

#### Example Output

**Annotation Summary (CSV):**
| Tool | Annotated Genes | Total Genes | Percentage | Percentage_Value |
|------|----------------|-------------|------------|------------------|
| KofamScan | 8532 | 12000 | 71.10% | 71.10 |
| InterProScan | 9245 | 12000 | 77.04% | 77.04 |
| EggNOG (GO) | 8891 | 12000 | 74.09% | 74.09 |
| EggNOG (KEGG) | 7234 | 12000 | 60.28% | 60.28 |
| FANTASIA ESM-2 (pre) | 6789 | 12000 | 56.58% | 56.58 |
| FANTASIA ESM-2 (post) | 5123 | 12000 | 42.69% | 42.69 |

**Overlap Summary (TXT):**
```
============================================================
Gene Annotation Overlap Analysis
============================================================

All tools combined: 10234 genes
Genes annotated by ALL tools: 5678 genes

------------------------------------------------------------
KofamScan + InterProScan + EggNOG Analysis:
------------------------------------------------------------
Combined (union): 9876 genes
Overlap (intersection): 6543 genes

------------------------------------------------------------
FANTASIA Unique Contributions:
------------------------------------------------------------
Genes uniquely annotated by FANTASIA: 358 genes
(These genes were not annotated by KofamScan, InterProScan, or EggNOG)
```

#### Interpretation Guide

**High annotation percentage (>70%)**: Tool successfully annotated most genes

**Low annotation percentage (<50%)**: 
- Tool may be more specific/stringent
- May indicate incomplete reference databases
- Or tool specializes in certain gene types

**FANTASIA unique genes**: Genes that traditional tools missed but AI-based prediction found

**Overlap between tools**: 
- High overlap (>60%): Tools are consistent in their annotations
- Low overlap (<40%): Tools may be complementary, catching different gene types

#### Integration with Pipeline

This script is designed to be run after `create_excel_outputs.py` and optionally `filter_fantasia_results.py`:

```bash
# After annotation steps complete (02-06), run:
cd scripts/INTEGRATION

# Generate Excel outputs
python create_excel_outputs.py

# Optionally filter FANTASIA
python filter_fantasia_results.py \
  --summary ../../results/fantasia/sample.tsv \
  --excel-dir excel_outputs/

# Analyze and visualize
python analyze_annotation_results.py \
  --fasta ../../proteins/sample.faa \
  --excel-dir excel_outputs/ \
  --sample sample
```

#### Troubleshooting

**Error: FASTA file not found**
- Verify the path to the FASTA file is correct
- Ensure the file exists and is readable

**Warning: File not found for tool**
- Some tools may not have been run yet
- Check that `create_excel_outputs.py` completed successfully
- Verify file naming matches expected pattern: `{sample}_{tool}_per_gene.xlsx`

**Empty or zero annotations**
- Check that the per-gene Excel files contain data
- Verify annotation columns are not all empty
- Review individual tool outputs for errors

**FANTASIA filtered files not found**
- Filtered files only exist after running `filter_fantasia_results.py`
- Script will use unfiltered results for post-filtering if filtered files don't exist
- This is expected behavior if you haven't run the filter script

**Matplotlib/plotting errors**
- Ensure matplotlib is installed: `pip install matplotlib`
- On headless servers, you may need to set backend: `export MPLBACKEND=Agg`

#### Notes

- The script handles missing files gracefully - it will analyze whatever tools are available
- EggNOG version detection is automatic (works with both v5 and v7)
- FANTASIA analysis includes all 5 models if available
- Gene IDs are extracted from FASTA headers (first word after '>')
- All visualizations are saved as high-resolution PNG files (300 DPI)
