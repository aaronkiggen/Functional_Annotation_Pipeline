#!/bin/bash
# ==============================================================================
# Script: install_braker4.sh
# Description: Installation script/guide for BRAKER4 and VARSUS
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Define installation directories
INSTALL_DIR="${HOME}/software"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

echo "========================================"
echo "    Installing BRAKER4 (Snakemake)      "
echo "========================================"
# BRAKER4 is a Snakemake pipeline that uses Singularity/Apptainer containers automatically.

# 1. Clone the BRAKER4 repository
if [ ! -d "BRAKER4" ]; then
    git clone https://github.com/Gaius-Augustus/BRAKER4.git
fi
cd BRAKER4

# 2. Setup Snakemake environment
echo "Setting up Snakemake environment..."
python3 -m venv snakemake_env
source snakemake_env/bin/activate
pip install --upgrade pip
pip install snakemake==8.18.2
pip install snakemake-executor-plugin-slurm==2.6.0

echo "Snakemake installation complete."
echo "Note: BRAKER4 will automatically pull Singularity containers (including VARSUS and FANTASIA-Lite) on the first run."

echo "========================================"
echo " Installing OrthoFinder (If needed)     "
echo "========================================"
conda create -n orthofinder -c bioconda orthofinder -y

echo "========================================"
echo "Installation structure prepared.        "
echo "BRAKER4 is ready in ${INSTALL_DIR}/BRAKER4."
echo "========================================"
