#!/bin/bash
# ==============================================================================
# Script: install_braker4.sh
# Description: Installation script/guide for BRAKER4 and VARSUS
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Source the configuration file to load VSC_SCRATCH
source "$(dirname "$0")/../config.env"

# Define installation directories
INSTALL_DIR="${PIPELINE_SCRATCH}/software"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# Set Singularity/Apptainer cache to scratch to prevent filling up $HOME
export APPTAINER_CACHEDIR="${PIPELINE_SCRATCH}/apptainer_cache"
export SINGULARITY_CACHEDIR="${PIPELINE_SCRATCH}/apptainer_cache"
mkdir -p "${APPTAINER_CACHEDIR}"

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
echo "Setting up Snakemake environment via Conda (requires Python 3.11+)..."
# Source conda appropriately
source /data/leuven/354/vsc35429/miniconda3/etc/profile.d/conda.sh
conda create -n braker_snakemake -c conda-forge -c defaults python=3.11 -y
conda activate braker_snakemake
pip install --upgrade pip
pip install snakemake==8.18.2
pip install snakemake-executor-plugin-slurm==2.6.0

echo "Snakemake installation complete."
echo "Note: BRAKER4 will automatically pull Singularity containers (including VARSUS and FANTASIA-Lite) on the first run."

echo "========================================"
echo "Installation structure prepared.        "
echo "BRAKER4 is ready in ${INSTALL_DIR}/BRAKER4."
echo "Conda environments will now default to ${VSC_SCRATCH}/conda_envs."
echo "Apptainer images will be cached to ${APPTAINER_CACHEDIR}."
echo "========================================"
