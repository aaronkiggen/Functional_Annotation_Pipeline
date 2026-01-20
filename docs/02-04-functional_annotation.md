# Steps 02-04: Functional Annotation Modules

This document covers the three primary functional annotation tools in the pipeline:

- **Step 02**: KofamScan (KEGG Orthology)
- **Step 03**: InterProScan (Protein domains and motifs)
- **Step 04**: EggNOG-mapper (Orthology and GO terms)

---

## Step 02: KofamScan - KEGG Orthology Annotation

### Overview

KofamScan uses profile Hidden Markov Models (HMMs) to assign KEGG Ortholog (KO) identifiers to protein sequences. KO assignments enable pathway reconstruction and metabolic analysis.

### Key Features

- **Database**: KofamKOALA HMM profiles (~24,000 KOs)
- **Method**:  HMMER3-based profile search
- **Output**: KO assignments with E-values and scores
- **Speed**: ~1,000-5,000 proteins/hour (varies by hardware)

### Installation

#### Conda Environment

```bash
conda create -n kofam python=3.9
conda activate kofam
conda install -c bioconda kofamscan hmmer
```

#### Database Setup

```bash
# Download KOfam database
wget ftp://ftp.genome.jp/pub/db/kofam/ko_list.gz
wget ftp://ftp.genome.jp/pub/db/kofam/profiles. tar.gz

# Extract
gunzip ko_list.gz
tar xzf profiles.tar.gz
```

### Running KofamScan

#### SLURM Script

```bash
sbatch 02_run_kofamscan.sh
```

#### Resource Requirements

```bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=32GB
#SBATCH --time=12:00:00
```

#### Command Structure

```bash
exec_annotation \
  -o output. txt \
  -p /path/to/profiles \
  -k /path/to/ko_list \
  --cpu 16 \
  --tmp-dir /scratch \
  input_proteins.faa
```

### Output Format

#### Mapper File (TSV)

```
# gene name    KO      threshold    score    E-value
gene001.t1     K00001  100.00       150.2    1.2e-45
gene002.t1     K00002  85.50        92.3     3.4e-28
```

#### Columns Explained

- **gene name**: Query sequence identifier
- **KO**:  KEGG Ortholog identifier
- **threshold**: Minimum score for assignment
- **score**: Bit score from HMM search
- **E-value**: Statistical significance

### Post-Processing

#### Count KO Assignments

```bash
grep -v "^#" kofamscan_output.txt | wc -l
```

#### Extract Pathway Information

```bash
# Download KO-to-pathway mapping
wget ftp://ftp.genome.jp/pub/db/kofam/ko_to_pathway.txt

# Map your KOs to pathways
join <(cut -f2 kofamscan_output. txt | sort -u) \
     <(sort ko_to_pathway.txt)
```

### Troubleshooting

**Issue**: Very long runtime  
**Solution**: Split input file and run parallel jobs

```bash
split -l 1000 input.faa chunk_
for chunk in chunk_*; do
    sbatch --export=INPUT=$chunk 02_run_kofamscan.sh
done
```

---

## Step 03: InterProScan - Domain and Motif Analysis

### Overview

InterProScan is a meta-tool that runs **multiple** domain detection algorithms simultaneously: 

- Pfam (protein families)
- SUPERFAMILY (structural domains)
- TIGRFAM (functionally equivalent homologs)
- SMART (signaling domains)
- PRINTS (protein fingerprints)
- And 10+ others

### Key Features

- **Comprehensive**: Integrates 15+ databases
- **Standardized**: Outputs InterPro IDs (unified classification)
- **Flexible**: Multiple output formats (TSV, GFF3, XML, JSON)
- **Resource-Intensive**: CPU and I/O demanding

### Installation

#### Binary Download

```bash
wget https://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.XX-XX. X/interproscan-5.XX-XX.X-64-bit.tar.gz
tar -xzf interproscan-5.XX-XX.X-64-bit.tar.gz
cd interproscan-5.XX-XX.X
./interproscan.sh --help
```

### Running InterProScan

#### SLURM Script

```bash
sbatch 03_run_interproscan.sh
```

#### Resource Requirements

```bash
#SBATCH --cpus-per-task=32
#SBATCH --mem=64GB
#SBATCH --time=48:00:00  # Can be very long! 
```

#### Command Structure

```bash
interproscan.sh \
  -i input_proteins.faa \
  -d output_dir \
  -f TSV,GFF3 \
  -cpu 32 \
  -appl Pfam,TIGRFAM,SUPERFAMILY \
  -goterms \
  -iprlookup \
  -pa
```

#### Key Parameters

- `-appl`: Specific applications to run (or omit for all)
- `-goterms`: Include Gene Ontology annotations
- `-iprlookup`: Map to InterPro entries
- `-pa`: Enable precalculated matches (faster)

### Output Formats

#### TSV Format

```
P12345  MD5HASH  123  Pfam  PF00001  Zinc finger  50  100  1.2e-15  T  01-01-2025
```

#### GFF3 Format

```gff3
gene001.t1  InterProScan  protein_match  50  100  1.2e-15  .   .  Name=PF00001;signature_desc=Zinc finger
```

### Performance Optimization

#### Use Lookup Service

Enable the precalculated match lookup service:

```bash
interproscan.sh -i input. faa --enable-lookup -pa
```

This reduces runtime by **50-70%** for well-studied proteins.

#### Split Large Files

```bash
# Split into 1000-sequence chunks
split -l 2000 input.faa chunk_  # 2 lines per sequence

for chunk in chunk_*; do
    sbatch --export=INPUT=$chunk 03_run_interproscan.sh
done
```

#### Disable Slow Applications

If time is critical, skip computationally expensive apps:

```bash
-appl Pfam,Gene3D,SMART  # Skip PANTHER, which is very slow
```

### Troubleshooting

**Issue**: "Too many open files"  
**Solution**: Increase file descriptor limit

```bash
ulimit -n 4096
```

**Issue**: Java heap space error  
**Solution**: Increase JVM memory

```bash
export _JAVA_OPTIONS="-Xms2G -Xmx16G"
```

---

## Step 04: EggNOG-mapper - Rapid Orthology Assignment

### Overview

EggNOG-mapper performs fast functional annotation using precomputed orthologous groups. It assigns: 

- **EggNOG Orthologous Groups (OGs)**
- **Gene Ontology (GO) terms**
- **KEGG pathways**
- **BiGG metabolic reactions**
- **Functional descriptions**

### Key Features

- **Speed**: 10-100x faster than InterProScan
- **Taxonomic specificity**: Can scope to clades (e.g., Arthropoda)
- **Multi-database**: Aggregates COG, KOG, arNOG, etc.
- **Low resource**:  Requires only ~8-16 GB RAM

### Installation

#### Conda Environment

```bash
conda create -n eggnog_2025 python=3.10
conda activate eggnog_2025
conda install -c bioconda eggnog-mapper
```

#### Database Download

```bash
download_eggnog_data.py -y --data_dir /path/to/eggnog_data
```

**Size**: ~80 GB for full database

### Running EggNOG-mapper

#### SLURM Script

```bash
sbatch 04_run_eggnog. sh
```

#### Resource Requirements

```bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=16GB
#SBATCH --time=06:00:00
```

#### Command Structure

```bash
emapper.py \
  -i input_proteins.faa \
  -o output_prefix \
  --cpu 16 \
  --data_dir /path/to/eggnog_data \
  --tax_scope Arthropoda \
  -m diamond \
  --override
```

#### Key Parameters

- `--tax_scope`: Taxonomic scope (2759=Eukaryota, 6656=Arthropoda, 1=root)
- `-m diamond`: Use DIAMOND (fast) or `mmseqs` (more sensitive)
- `--override`: Overwrite existing results

### Output Files

#### Main Annotation File (`.emapper.annotations`)

```
#query  seed_ortholog  evalue  score  eggNOG_OGs  GO_terms  KEGG_ko  Description
gene001.t1  12345.XP_001  1e-100  500  COG0001@1|root  GO:0005515  ko:K00001  Protein kinase
```

#### Ortholog File (`.emapper.seed_orthologs`)

Lists best-matching sequences from reference database. 

#### Excel Summary

For quick viewing, convert to Excel: 

```bash
csvtool readable output.emapper.annotations > output.xlsx
```

### Post-Processing

#### Count Annotated Genes

```bash
grep -v "^#" output.emapper.annotations | cut -f1 | sort -u | wc -l
```

#### Extract GO Terms

```bash
awk -F'\t' '{print $7}' output.emapper.annotations | \
  tr ',' '\n' | \
  grep "^GO:" | \
  sort -u
```

#### Pathway Enrichment

Use the KEGG KO column for pathway analysis:

```bash
cut -f11 output.emapper.annotations | grep "ko:" > ko_list.txt
```

### Comparing Results

#### KofamScan vs EggNOG-mapper

- **Overlap**:  Typically 70-85% agreement on KO assignments
- **KofamScan**: More specific, profile-based
- **EggNOG**:  Broader, includes additional databases

#### InterProScan vs EggNOG-mapper

- **Complementary**: Use both for complete annotation
- **InterProScan**: Domain architecture details
- **EggNOG**: High-level function and pathways

---

## Integrated Analysis

### Merge Annotations

Combine all three tools into a master table:

```python
import pandas as pd

kofam = pd.read_csv("kofamscan. txt", sep="\t")
interpro = pd.read_csv("interproscan.tsv", sep="\t")
eggnog = pd.read_csv("output.emapper.annotations", sep="\t", comment="#")

merged = kofam.merge(eggnog, left_on="gene", right_on="query", how="outer")
merged.to_csv("integrated_annotations.csv", index=False)
```

### Visualization

Use R or Python for annotation coverage plots:

```R
library(ggplot2)

coverage <- data.frame(
  Tool = c("KofamScan", "InterProScan", "EggNOG"),
  Annotated = c(8500, 9200, 9800),
  Total = 10000
)

ggplot(coverage, aes(x=Tool, y=Annotated/Total*100, fill=Tool)) +
  geom_bar(stat="identity") +
  labs(y="% Proteins Annotated", title="Annotation Coverage")
```

---

**Expected Total Runtime**: 1-5 days (species-dependent)  
**Total Disk Space**: ~500 GB (databases + results)  
**Recommended**:  Run Steps 02-04 in parallel to save time
