# Steps 02-04: Functional Annotation

Three complementary annotation tools:
- **Step 02**: KofamScan - KEGG Orthology via HMM profiles
- **Step 03**: InterProScan - Protein domains and motifs
- **Step 04**: EggNOG-mapper - Rapid orthology and GO terms

**Run in parallel to save time (total: 1-5 days)**

---

## Step 02: KofamScan

Assigns KEGG Ortholog (KO) identifiers using profile HMMs.

### Installation
```bash
conda create -n kofam python=3.9
conda activate kofam
conda install -c bioconda kofamscan hmmer

# Download database (~5 GB)
wget ftp://ftp.genome.jp/pub/db/kofam/ko_list.gz
wget ftp://ftp.genome.jp/pub/db/kofam/profiles.tar.gz
gunzip ko_list.gz && tar xzf profiles.tar.gz
```

### Usage
```bash
sbatch 02_run_kofamscan.sh
```

**Resources**: 16 CPUs, 32 GB RAM, ~12 hours

### Output Format (TSV)
```
gene_name    KO      threshold    score    E-value
gene001.t1   K00001  100.00       150.2    1.2e-45
```

### Troubleshooting
**Long runtime**: Split input and run parallel jobs
```bash
split -l 1000 input.faa chunk_
for f in chunk_*; do sbatch --export=INPUT=$f 02_run_kofamscan.sh; done
```

---

## Step 03: InterProScan

Integrates 15+ domain databases (Pfam, TIGRFAM, SUPERFAMILY, etc.)

### Installation
```bash
wget https://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.XX-XX.X/interproscan-5.XX-XX.X-64-bit.tar.gz
tar -xzf interproscan-5.XX-XX.X-64-bit.tar.gz
```

### Usage
```bash
sbatch 03_run_interproscan.sh
```

**Resources**: 32 CPUs, 64 GB RAM, up to 48 hours

### Command
```bash
interproscan.sh -i input.faa -d output_dir -f TSV,GFF3 \
  -cpu 32 -goterms -iprlookup -pa
```

**Key options**:
- `-pa`: Use precalculated matches (50-70% faster)
- `-appl Pfam,Gene3D,SMART`: Select specific databases (faster)

### Troubleshooting
**Too many open files**: `ulimit -n 4096`

**Java heap space**: `export _JAVA_OPTIONS="-Xms2G -Xmx16G"`

---

## Step 04: EggNOG-mapper

Fast orthology assignment with GO terms and KEGG pathways.

### Installation
```bash
conda create -n eggnog_2025 python=3.10
conda activate eggnog_2025
conda install -c bioconda eggnog-mapper

# Download database (~80 GB)
download_eggnog_data.py -y --data_dir /path/to/eggnog_data
```

### Usage
```bash
sbatch 04_run_eggnog.sh
```

**Resources**: 16 CPUs, 16 GB RAM, ~6 hours

### Command
```bash
emapper.py -i input.faa -o output --cpu 16 \
  --data_dir /path/to/eggnog_data \
  --tax_scope 2759 -m diamond
```

**Tax scopes**: `1` (all), `2759` (Eukaryota), `6656` (Arthropoda)

### Output (`.emapper.annotations`)
```
#query      seed_ortholog  evalue   eggNOG_OGs  GO_terms    KEGG_ko  Description
gene001.t1  12345.XP_001   1e-100   COG0001     GO:0005515  ko:K00001  Protein kinase
```

---

## Integrated Analysis

### Merge Results
```python
import pandas as pd

kofam = pd.read_csv("kofamscan.txt", sep="\t")
interpro = pd.read_csv("interproscan.tsv", sep="\t")
eggnog = pd.read_csv("output.emapper.annotations", sep="\t", comment="#")

merged = kofam.merge(eggnog, left_on="gene", right_on="query", how="outer")
merged.to_csv("integrated_annotations.csv")
```

### Tool Comparison
- **KofamScan vs EggNOG**: 70-85% agreement on KO assignments
- **InterProScan + EggNOG**: Complementary - use both for comprehensive annotation
