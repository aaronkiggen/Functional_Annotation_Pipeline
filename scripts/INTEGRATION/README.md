# Integration Scripts

This directory contains scripts for integrating and formatting outputs from the functional annotation pipeline.

## Scripts

### create_excel_outputs.py

A Python script that parses output files from functional annotation tools and generates Excel files with standardized format.

#### Output Format

Each Excel file contains three columns:
- **gene_name**: The identifier of the gene/protein
- **functional_term**: GO term or KEGG ortholog identifier
- **extra_information**: Additional details from the tool (e.g., protein name, scores, E-values)

#### Supported Tools

The script processes outputs from:

1. **KofamScan** - KEGG Orthology annotation
   - Input: `*_kofam_mapper.tsv` files
   - Functional terms: KEGG KO identifiers (e.g., K00001)
   - Extra information: Score, E-value, Threshold

2. **InterProScan** - Domain and motif analysis
   - Input: `*.tsv` files
   - Functional terms: GO terms and domain accessions
   - Extra information: Domain descriptions, InterPro IDs

3. **EggNOG-mapper** - Orthology and functional annotation
   - Input: `.emapper.annotations` files (v5) and `.eggnog.tsv.gz` files (v7)
   - Functional terms: GO terms and KEGG KO identifiers
   - Extra information: Protein descriptions, best hits, E-values

4. **FANTASIA** - AI-driven functional annotation
   - Input: `*.tsv` files from FANTASIA output directory
   - Functional terms: GO terms
   - Extra information: Final scores per model, similar proteins
   - Output: One Excel file per model (ESM-2, ProtT5, ProstT5, Ankh3-Large, ESM3c)
   - Columns: gene_name, GO, final_score, proteins

**Note**: OrthoFinder outputs are excluded as per requirements.

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
                                [--eggnog-only]

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

The script generates one Excel file per input sample and tool:

- `{sample}_kofamscan_annotations.xlsx` - KofamScan results
- `{sample}_interproscan_annotations.xlsx` - InterProScan results
- `{sample}_eggnog_v5_annotations.xlsx` - EggNOG v5 results
- `{sample}_eggnog_v7_annotations.xlsx` - EggNOG v7 results
- `{sample}_fantasia_ESM-2_annotations.xlsx` - FANTASIA ESM-2 model results
- `{sample}_fantasia_ProtT5_annotations.xlsx` - FANTASIA ProtT5 model results
- `{sample}_fantasia_ProstT5_annotations.xlsx` - FANTASIA ProstT5 model results
- `{sample}_fantasia_Ankh3-Large_annotations.xlsx` - FANTASIA Ankh3-Large model results
- `{sample}_fantasia_ESM3c_annotations.xlsx` - FANTASIA ESM3c model results

Each Excel file includes:
- Formatted headers (blue background, white text)
- Auto-sized columns for readability
- All annotations for the sample

#### Example Output

| gene_name | functional_term | extra_information |
|-----------|----------------|-------------------|
| gene001.t1 | K00001 | Score: 150.2, E-value: 1.2e-45, Threshold: 100.00 |
| gene001.t1 | GO:0005515 | Domain: Zinc finger (PF00001); InterPro: Zinc finger domain (IPR000001) |
| gene002.t1 | K00002 | Description: Protein kinase; Best hit: 12345.XP_001; E-value: 1e-100 |

For FANTASIA results (one file per model):

| gene_name | GO | final_score | proteins |
|-----------|-------|-------------|----------|
| KAK4001893.1 | GO:0000281 | 0.5404 | TALAN_HUMAN |
| KAK4001894.1 | GO:0003676 | 0.5876 | DDX5_HUMAN;RBM3_MOUSE |

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
