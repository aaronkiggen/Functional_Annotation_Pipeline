# Functional Annotation Pipeline

A modular HPC pipeline for comprehensive functional annotation of genomic protein data. This repository contains a suite of SLURM scripts designed to run on VSC (Flemish Supercomputer Center) infrastructure.

## ?? Pipeline Overview

This pipeline performs annotation in 6 distinct stages. Each stage is independent but designed to work sequentially on the output of previous steps.

| Step | Tool | Description |
| :--- | :--- | :--- |
| **01** | **Python/Biopython** | Extraction of longest isoforms/primary transcripts |
| **02** | **KofamScan** | KEGG Orthology annotation using HMM profiles |
| **03** | **InterProScan** | Domain and motif classification (Pfam, SUPERFAMILY, etc.) |
| **04** | **EggNOG-mapper** | Orthology prediction and functional annotation |
| **05** | **OrthoFinder** | Phylogenetic orthology inference |
| **06** | **FANTASIA** | AI-driven functional annotation (GPU accelerated) |

## ?? Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/aaronkiggen/Functional_Annotation_Pipeline.git
   cd Functional_Annotation_Pipeline
Configure Environment: Edit the config.env file to match your cluster paths, database locations, and Conda environment names.

bash
nano config.env
Install Dependencies: Ensure you have the following Conda environments created:

kofam (KofamScan installed)
eggnog_2025 (EggNOG-mapper installed)
of3 (OrthoFinder installed)
?? Usage
Submit jobs individually using sbatch. Ensure you are in the scripts/ directory.

Basic Workflow
bash
cd scripts/

# 1. Clean input data
sbatch 01_extract_longest_isoform.sh

# 2. Run functional annotations (can run in parallel)
sbatch 02_run_kofamscan.sh
sbatch 03_run_interproscan.sh
sbatch 04_run_eggnog.sh

# 3. Comparative Genomics
sbatch 05_run_orthofinder.sh

# 4. Deep Learning Annotation
sbatch 06_run_fantasia.slurm
?? Documentation
Detailed documentation for specific modules can be found in the docs/ folder:

Preprocessing Guide
Functional Annotation Details
?? Future Work
 Downstream Analysis: R scripts for parsing and visualizing annotation density.
 Integration: Merging GFF3 files from all tools into a consensus annotation.
Maintained by Aaron Kiggen
