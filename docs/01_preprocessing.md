# Step 01: Preprocessing - Longest Isoform Extraction

## Overview

Extracts the longest protein isoform per gene to reduce redundancy and improve annotation accuracy.

## Usage

```bash
cd scripts/
sbatch 01_extract_longest_isoform.sh
```

## Configuration

Edit `config.env` or the script to set:
```bash
INPUT_DIR="/path/to/raw/proteins"
OUTPUT_DIR="/path/to/primary_transcripts"
FILE_PATTERN="*.faa"
```

## Requirements

- **Input**: Protein FASTA files (`.faa` or `.fasta`)
- **Resources**: 4-8 GB RAM, 1-4 CPUs
- **Runtime**: 10-60 minutes

## Troubleshooting

**No sequences in output**: Check FASTA header format matches script parsing pattern

**Out of memory**: Increase `--mem` to 32GB or process files in batches

**Expected reduction**: 30-60% fewer sequences

## Validation

```bash
# Check sequence count before/after
grep -c "^>" input.faa
grep -c "^>" output.faa

# Verify no duplicate gene IDs
grep "^>" output.faa | cut -d'.' -f1 | sort | uniq -d
```
