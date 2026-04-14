# Functional Annotation Pipeline

A modular HPC pipeline for comprehensive functional annotation of genomic protein data.  This repository contains a suite of SLURM scripts designed to run on High-Performance Computing (HPC) cluster infrastructure.

## 🔄 Pipeline Overview

This pipeline performs annotation in 6 distinct stages. Each stage is independent but will be integrated in the final step to perform a coherent, unified functional annotation across tools

| Step | Tool | Description |
| :--- | :--- | :--- |
| **01** | **Bash/Python** | Configuration generation (`samples.csv`, `config.ini`) and reference DB downloads |
| **02** | **BRAKER4/VARSUS** | Primary transcript creation via auto-retrieved SRA RNA-seq, and FANTASIA Deep Learning prediction |
| **03** | **OrthoFinder / Python** | Single-baseline (`_prot`) orthology inference & comprehensive QC statistic aggregation |
| **04** | **KofamScan & InterPro** | Domain and motif classification against Pfam, SUPERFAMILY, KEGG HMM profiles |
| **05** | **EggNOG-mapper** | Standardized Orthology prediction and functional annotation |
| **06** | **INTEGRATION** | Wang Semantic Similarity GO evaluation, unifying FANTASIA vs. Classical predictions into structured DataFrames |

## ⚙️ Requirements

### Required Inputs & Databases
To run this pipeline, you must provide the following inputs and ensure the backend databases are accessible.

**1. User-Provided Inputs:**
- **Genome Assemblies:** Raw unmasked genome `.fa` files (e.g., `Daphnia_pulex.fa`). The pipeline handles repeat-masking natively.
- **Species Metadata:** Genus and species names (e.g., `Daphnia` and `pulex`). Used by the pipeline to automatically download the best available RNA-seq evidence from the NCBI SRA via VARSUS.

**2. Required Databases (Downloaded during setup):**
- **OrthoDB Protein Partition:** A high-confidence protein reference database for your specific clade (e.g., `Arthropoda.fa` from OrthoDB v12). The preparation script (`scripts/01_prep_braker4.sh`) auto-downloads this.
- **EggNOG Mapper Data:** The generic `eggnog_proteins.dmnd` and `eggnog.db` files.
- **InterProScan & KofamScan DBs:** Local HMM profiles and InterPro databases (Pfam, Panther, etc.).
- **FANTASIA Models:** The ProtT5 Deep Learning weights are automatically pulled and managed by the BRAKER4 Apptainer/Singularity container on first run.
- **Gene Ontology (GO) Hierarchy:** The latest `go-basic.obo` is automatically fetched during the QC steps to calculate Wang Semantic Similarity scores.

### System Requirements

This pipeline is designed to run on **SLURM-managed HPC clusters**. It has been tested on the **VSC (Flemish Supercomputer Center)** infrastructure with access to sufficient memory, CPUs and GPUs but should work on any modern HPC system with SLURM. 

**Supported GPUs:**
- ✅ NVIDIA H100 (optimal for large-scale annotations)
- ✅ NVIDIA A100 (40 GB or 80 GB) - **Recommended**
- ✅ NVIDIA V100 (32 GB) - Minimum for FANTASIA
- ⚠️ NVIDIA RTX 4090/3090 (24 GB) - Works for small datasets only
- ❌ AMD GPUs - Not currently supported


## 📦 Installation & Setup

### 1. Clone the repository

```bash
git clone https://github.com/aaronkiggen/Functional_Annotation_Pipeline.git
cd Functional_Annotation_Pipeline
```

### 2. Configure Environment

Edit the `config.env` file to match your cluster paths, database locations, and Conda environment names. 

```bash
nano config.env
```

### 3. Install Dependencies

Please refer to the scripts located in the `installation/` directory to set up the necessary Conda environments and databases.

```bash
cd installation/
# See the scripts: environments_and_databases, interproscan, FANTASIA, and download_eggnog_data.py
```

For detailed installation instructions for each tool, see the respective readthedocs of the tools used. 

## 🚀 Usage

Submit jobs individually using `sbatch`. Ensure you are in the `scripts/` directory. 

### Basic Workflow

```bash
cd scripts/

# 1. Prepare Genomes & Configure BRAKER4
# Downloads OrthoDB proteins and creates samples.csv mapping
bash 01_prep_braker4.sh

# 2. Base Annotation (BRAKER4 + VARSUS RNA-seq + FANTASIA)
sbatch 02_run_braker4_slurm.sh
sbatch 02b_run_orthofinder.sh
python3 03_step1_summary.py --braker_dir ../results/braker4/output --orthofinder_dir ../results/orthofinder --output ../results/Step1_Summary.xlsx

# 3. Extra Functional Annotations (EggNOG, InterProScan, KofamScan)
sbatch 04_run_step2_functional.sh

# 4. Deep Integration & QC Evaluation
# Integrates all Excel sheets and computes Semantic Wang GO-Similarity
sbatch 06_run_step3_integration.sh
```

## 📖 Documentation

Comprehensive documentation for each pipeline component is available in the `docs/` directory. Each guide includes installation instructions, usage examples, troubleshooting tips, and best practices. 

### Step 01: Preprocessing
**📄 [Preprocessing Guide](docs/01_preprocessing.md)**

Learn how to extract longest isoforms from multi-isoform protein FASTA files.  This guide covers:
- Why preprocessing is necessary
- Input/output formats
- Quality control checks
- Troubleshooting common issues
- **Runtime**: 10-60 minutes

### Steps 02-04: Functional Annotation
**📄 [Functional Annotation Details](docs/02-04_functional_annotation.md)**

Complete guide covering three complementary annotation tools:
- **KofamScan**: KEGG Orthology assignment using HMM profiles
- **InterProScan**: Domain and motif detection (Pfam, TIGRFAM, SUPERFAMILY, etc.)
- **EggNOG-mapper**: Fast orthology and GO term annotation
- Includes performance optimization, output parsing, and integration strategies
- **Runtime**: 5-8 hours in parallel 

### Step 05: Comparative Genomics
**📄 [OrthoFinder Guide](docs/05_orthofinder.md)**

Phylogenetic orthology inference and comparative genomics analysis:
- Orthogroup identification
- Species tree reconstruction
- Gene duplication detection
- Core genome identification
- Gene family expansion analysis
- **Runtime**: 2 hours (depending on dataset size)

### Step 06: AI-Driven Annotation
**📄 [FANTASIA Setup](docs/06_fantasia.md)**

Advanced GPU-accelerated functional annotation using Large Language Models:
- Hardware requirements (NVIDIA A100/H100)
- PostgreSQL with pgvector setup
- LLM model configuration
- Integration with traditional annotations
- **Runtime**: 4-15 hours (GPU-dependent)

### Step 07: Integration & Output Generation
**📂 [Integration Scripts](scripts/INTEGRATION/README.md)**

Generate standardized Excel outputs and perform post-processing filtering:
- **create_excel_outputs.py**: Convert all annotation results to formatted Excel files
  - Creates per-term and per-gene outputs for each tool
  - Standardized formatting with headers and column widths
  - Supports KofamScan, InterProScan, EggNOG-mapper, and FANTASIA
- **filter_fantasia_results.py**: Post-process FANTASIA results with threshold filtering
  - Calculate 25th percentile (Q1) thresholds for each model
  - Filter individual model Excel files (Task A)
  - Create consensus results with majority vote ≥3/5 models (Task B)
  - Optional protein-to-gene mapping from FASTA
- **Runtime**: 5-15 minutes for typical datasets

## 📊 Expected Results

After running the complete pipeline, you will have: 

- ✅ **Cleaned proteomes**: Longest isoforms only, reducing redundancy
- ✅ **KEGG pathways**: KO assignments for metabolic reconstruction
- ✅ **Protein domains**:  Pfam, TIGRFAM, and other domain annotations
- ✅ **GO terms**: Gene Ontology functional classifications
- ✅ **Orthogroups**: Gene families across species
- ✅ **Species tree**: Phylogenetic relationships
- ✅ **AI predictions**: Context-aware functional descriptions

## 🔮 Future Work

- [✅] **Downstream Analysis**: R scripts for parsing and visualizing annotation density
- [ ] **GFF3 generation**: from concensus annotation create a GFF3 file
- [✅] **TopGO output**: from concensus GO terms create a TopGO suitable output file for downstream analyses


## 📝 Citation

If you use this pipeline in your research, please cite the relevant tools:

- **KofamScan**:  Aramaki et al. (2020) *Bioinformatics* 36(7):2251-2252
- **InterProScan**: Jones et al. (2014) *Bioinformatics* 30(9):1236-1240
- **EggNOG-mapper**: Huerta-Cepas et al. (2019) *Mol Biol Evol* 36(10):2226-2229
- **eggnog7_annotator**: [fischuu/eggnog7_annotator](https://github.com/fischuu/eggnog7_annotator) - EggNOG v7 annotation tool
- **OrthoFinder**: Emms & Kelly (2019) *Genome Biology* 20:238
- **FANTASIA**:  [Add citation when available]

## 👤 Maintainer

**Aaron Kiggen**  
GitHub: [@aaronkiggen](https://github.com/aaronkiggen)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🆘 Getting Help

- **General questions**: Open an [issue](https://github.com/aaronkiggen/Functional_Annotation_Pipeline/issues)
- **Bug reports**: Use the issue tracker with the `bug` label
- **Feature requests**: Use the issue tracker with the `enhancement` label
- **Tool-specific issues**:  Consult the detailed documentation in `docs/`

---
