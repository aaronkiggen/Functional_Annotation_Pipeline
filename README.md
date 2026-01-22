# Functional Annotation Pipeline

A modular HPC pipeline for comprehensive functional annotation of genomic protein data.  This repository contains a suite of SLURM scripts designed to run on High-Performance Computing (HPC) cluster infrastructure.

## 🔄 Pipeline Overview

This pipeline performs annotation in 6 distinct stages. Each stage is independent but will be integrated in the final step to perform a coherent, unified functional annotation across tools

| Step | Tool | Description |
| :--- | :--- | :--- |
| **01** | **Python/Biopython** | Extraction of longest isoforms/primary transcripts |
| **02** | **KofamScan** | KEGG Orthology annotation using HMM profiles |
| **03** | **InterProScan** | Domain and motif classification (Pfam, SUPERFAMILY, etc.) |
| **04** | **EggNOG-mapper** | Orthology prediction and functional annotation |
| **05** | **OrthoFinder** | Phylogenetic orthology inference |
| **06** | **FANTASIA** | AI-driven functional annotation (GPU accelerated) |
| **07** | **INTEGRATION** | functional annotation integration and generation of output files |

## ⚙️ Requirements

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

### 3. Install Dependencies in **📄 [Installation Guide](installation)** 

Ensure you have the following Conda environments created:

- `kofam` (KofamScan and dependencies installed)
- `eggnog_2025` (EggNOG-mapper and dependencies installed)
- `of3` (OrthoFinder and dependencies installed)

Ensure you ran the installation scripts for:

- InterProScan
- FANTASIA

Ensure you have the right databases installed and that these are accessible
- KofamKOALA
- InterProScan
- EggNOG


For detailed installation instructions for each tool, see the respective readthedocs of the tools used. 

## 🚀 Usage

Submit jobs individually using `sbatch`. Ensure you are in the `scripts/` directory.

### Basic Workflow

```bash
cd scripts/

# 1. Clean input data
sbatch 01_extract_longest_isoform.sh

# 2. Run functional annotations (can run in parallel)
sbatch 02_run_kofamscan.sh
sbatch 03_run_interproscan.sh
sbatch 04_run_eggnog. sh

# 3. Comparative Genomics
sbatch 05_run_orthofinder.sh

# 4. Deep Learning Annotation
sbatch 06_run_fantasia.slurm
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

- [ ] **Downstream Analysis**: R scripts for parsing and visualizing annotation density
- [ ] **Integration**: Merging GFF3 files from all tools into a consensus annotation
- [ ] **Automated Testing**: CI/CD pipeline for validation
- [ ] **Containerization**: Docker/Singularity images for easier deployment

## 💡 Tips & Best Practices

### Resource Management
- **Steps 02-04 can run in parallel** to save time
- **Step 03 (InterProScan)** is the most time-consuming; consider splitting large datasets
- **Step 06 (FANTASIA)** requires GPU allocation; submit during off-peak hours

### Data Quality
- Always run **Step 01 (preprocessing)** first to ensure clean input
- Verify input FASTA headers are properly formatted
- Check intermediate outputs before proceeding to next steps

### Storage Requirements
- **Databases**: ~500 GB (KofamKOALA, EggNOG, InterProScan)
- **Results per species**: 10-50 GB (depending on proteome size)
- **Temporary files**: Can reach 100+ GB during InterProScan runs

## 📝 Citation

If you use this pipeline in your research, please cite the relevant tools:

- **KofamScan**:  Aramaki et al. (2020) *Bioinformatics* 36(7):2251-2252
- **InterProScan**: Jones et al. (2014) *Bioinformatics* 30(9):1236-1240
- **EggNOG-mapper**: Huerta-Cepas et al. (2019) *Mol Biol Evol* 36(10):2226-2229
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

For detailed instructions on each pipeline component, see the documentation guides in the [`docs/`](docs/) directory.
