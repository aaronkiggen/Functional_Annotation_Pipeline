#!/bin/bash
#SBATCH --job-name=pipeline_installation
#SBATCH --output=logs/install_%j.out
#SBATCH --error=logs/install_%j.err
#SBATCH --time=12:00:00
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

# ==============================================================================
# Script: run_installations.slurm
# Description: Executes all installation scripts safely on a compute node
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Jump to the pipeline root directory
cd "${SLURM_SUBMIT_DIR}"

# Source configurations
source config.env

echo "============================================================"
echo " Starting Full Pipeline Installation via Compute Node (SLURM)"
echo "============================================================"
echo "Target Scratch Path: ${VSC_SCRATCH}"

# Load necessary modules if required by your HPC
module load singularity || true

echo ""
echo "------------------------------------------------------------"
echo " [1/3] Installing BRAKER4 and Snakemake Virtual Environment"
echo "------------------------------------------------------------"
bash installation/00_install_braker4_varsus.sh

echo ""
echo "------------------------------------------------------------"
echo " [2/3] Setting up Conda Environments & Core Databases"
echo "------------------------------------------------------------"
bash installation/environments_and_databases

echo ""
echo "------------------------------------------------------------"
echo " [3/3] Installing InterProScan and Indexed HMM Models"
echo "------------------------------------------------------------"
bash installation/interproscan

echo ""
echo "============================================================"
echo "    Installation Process Completed Successfully!"
echo "============================================================"
