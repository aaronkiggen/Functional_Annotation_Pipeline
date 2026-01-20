# Step 01:  Preprocessing - Longest Isoform Extraction

## Overview

Many functional annotation tools perform optimally when protein redundancy is minimized. This preprocessing step filters a raw protein FASTA file containing multiple isoforms per gene and retains only the longest transcript variant for each gene.

## Why Extract Longest Isoforms? 

- **Reduces computational overhead**:  Fewer sequences = faster annotation
- **Avoids redundant annotations**: Prevents duplicate entries for the same gene
- **Improves orthology detection**: Simplifies comparative genomics analysis
- **Standard practice**: Most published annotation pipelines use primary transcripts

## Input Requirements

### File Format
- **Extension**: `.faa` or `.fasta`
- **Type**:  Protein sequences (amino acids)
- **Headers**: Standard FASTA format

### Supported Header Formats

The script can parse various header formats: 

```
>gene_id. isoform_id
>gene_id-T1
>TRINITY_DN1000_c0_g1_i1
>AT1G01010.1
```

### Example Input

```fasta
>gene001. t1
MSTLKPVQPQPQPQPQPQPQ
>gene001. t2
MSTLKPVQ
>gene002.t1
MAGKLLVVVAA LLLATAA
```

## Output

### Directory Structure

```
primary_transcripts/
├── species1_primary. faa
├── species2_primary.faa
└── ... 
```

### Example Output

```fasta
>gene001.t1
MSTLKPVQPQPQPQPQPQPQ
>gene002.t1
MAGKLLVVVAALLLATAA
```

Only the longest isoform (`gene001.t1`) is retained. 

## Running the Script

### SLURM Submission

```bash
cd scripts/
sbatch 01_extract_longest_isoform.sh
```

### Script Parameters

Edit the script header to customize: 

```bash
#SBATCH --job-name=extract_isoforms
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8GB
#SBATCH --time=01:00:00
```

### Configuration Variables

Set these in your script or `config.env`:

```bash
INPUT_DIR="/path/to/raw/proteins"
OUTPUT_DIR="/path/to/primary_transcripts"
FILE_PATTERN="*.faa"
```

## Algorithm Details

### Logic Flow

1. **Parse FASTA headers**: Extract gene ID (portion before `.` or `-`)
2. **Calculate lengths**: Count amino acids for each sequence
3. **Group by gene**: Collect all isoforms per gene
4. **Select longest**:  Retain the isoform with maximum length
5. **Write output**: Save filtered sequences to new file

### Pseudocode

```python
for each sequence in fasta:
    gene_id = extract_gene_id(header)
    length = len(sequence)
    
    if gene_id not in genes:
        genes[gene_id] = (header, sequence, length)
    else:
        if length > genes[gene_id][2]:
            genes[gene_id] = (header, sequence, length)

write_fasta(genes. values())
```

## Troubleshooting

### Issue: No sequences in output

**Cause**: Header parsing failed to identify gene IDs  
**Solution**: Check your FASTA headers and adjust the parsing regex

```python
# Modify the pattern in the script
pattern = r"(gene\d+)"  # Example for gene001, gene002, etc.
```

### Issue: Script runs out of memory

**Cause**: Very large FASTA files (>10M sequences)  
**Solution**: Increase memory allocation

```bash
#SBATCH --mem=32GB
```

Or process files in batches. 

### Issue: Multiple files not processed

**Cause**: Incorrect file glob pattern  
**Solution**: Verify your `FILE_PATTERN` matches your files

```bash
ls $INPUT_DIR/*.faa  # Check what files exist
```

## Quality Control

### Check Reduction Statistics

After running, verify the reduction:

```bash
echo "Before:"
grep -c "^>" raw_input.faa

echo "After:"
grep -c "^>" primary_transcripts/output.faa
```

### Expected Results

- Typical reduction: **30-60%** for model organisms
- **No reduction**:  Possible if input already contained only primary transcripts

### Validate Output

```bash
# Ensure no duplicate gene IDs
grep "^>" output.faa | cut -d'.' -f1 | sort | uniq -d
```

Should return empty if successful.

## Advanced Options

### Keep All Isoforms for Specific Genes

Modify the script to whitelist certain genes:

```python
KEEP_ALL = ["gene005", "gene123"]

if gene_id in KEEP_ALL:
    write_all_isoforms()
else:
    write_longest()
```

### Use Median Instead of Longest

```python
lengths = sorted([len(seq) for seq in isoforms])
median_length = lengths[len(lengths) // 2]
```

## Next Steps

After preprocessing, use the output files for: 

- **Step 02**: KofamScan annotation
- **Step 03**: InterProScan domain prediction
- **Step 04**: EggNOG-mapper functional annotation
- **Step 05**:  OrthoFinder comparative analysis

---

**Script**: `scripts/01_extract_longest_isoform.sh`  
**Expected Runtime**: 10-60 minutes (depends on file size)  
**Memory**: 4-16 GB  
**CPU**: 1-4 cores
