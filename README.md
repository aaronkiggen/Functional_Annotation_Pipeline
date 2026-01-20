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
