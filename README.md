# Functional Annotation Pipeline

A modular HPC pipeline for comprehensive functional annotation of genomic protein data. This repository contains a suite of SLURM scripts designed to run on VSC (Flemish Supercomputer Center) infrastructure.

## 🔄 Pipeline Overview

This pipeline performs annotation in 6 distinct stages. Each stage is independent but designed to work sequentially on the output of previous steps. 

| Step | Tool | Description |
| :--- | :--- | :--- |
| **01** | **Python/Biopython** | Extraction of longest isoforms/primary transcripts |
| **02** | **KofamScan** | KEGG Orthology annotation using HMM profiles |
| **03** | **InterProScan** | Domain and motif classification (Pfam, SUPERFAMILY, etc.) |
| **04** | **EggNOG-mapper** | Orthology prediction and functional annotation |
| **05** | **OrthoFinder** | Phylogenetic orthology inference |
| **06** | **FANTASIA** | AI-driven functional annotation (GPU accelerated) |

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

Ensure you have the following Conda environments created:

- `kofam` (KofamScan installed)
- `eggnog_2025` (EggNOG-mapper installed)
- `of3` (OrthoFinder installed)

## 🚀 Usage

Submit jobs individually using `sbatch`. Ensure you are in the `scripts/` directory.

### Basic Workflow

```bash
cd scripts/

# 1. Clean input data
sbatch 01_extract_longest_isoform.sh

# 2. Run functional annotations (can run in parallel)
sbatch 02_run_kofamscan.sh
sbatch 03_run_interproscan. sh
sbatch 04_run_eggnog.sh

# 3. Comparative Genomics
sbatch 05_run_orthofinder.sh

# 4. Deep Learning Annotation
sbatch 06_run_fantasia.slurm
```

## 📖 Documentation

Detailed documentation for specific modules can be found in the `docs/` folder:

- **[Preprocessing Guide](docs/01_preprocessing.md)** - Longest isoform extraction
- **[Functional Annotation Details](docs/02-04_functional_annotation.md)** - KofamScan, InterProScan, EggNOG-mapper
- **[OrthoFinder Guide](docs/05_orthofinder.md)** - Comparative genomics
- **[FANTASIA Setup](docs/06_fantasia. md)** - AI-driven annotation with GPU acceleration

## 🔮 Future Work

- [ ] **Downstream Analysis**: R scripts for parsing and visualizing annotation density
- [ ] **Integration**: Merging GFF3 files from all tools into a consensus annotation
- [ ] **Automated Testing**: CI/CD pipeline for validation
- [ ] **Containerization**: Docker/Singularity images for easier deployment

## 📝 Citation

If you use this pipeline in your research, please cite the relevant tools:

- **KofamScan**:  Aramaki et al. (2020) Bioinformatics
- **InterProScan**: Jones et al. (2014) Bioinformatics
- **EggNOG-mapper**: Huerta-Cepas et al. (2019) Molecular Biology and Evolution
- **OrthoFinder**: Emms & Kelly (2019) Genome Biology
- **FANTASIA**:  [Add citation when available]

## 👤 Maintainer

**Aaron Kiggen**  
GitHub: [@aaronkiggen](https://github.com/aaronkiggen)

## 📄 License

[Add license information]

---

For questions or issues, please open an [issue](https://github.com/aaronkiggen/Functional_Annotation_Pipeline/issues) on GitHub.
