#!/bin/bash
#SBATCH --job-name=braker4
#SBATCH --output=logs/braker4_%j.out
#SBATCH --error=logs/braker4_%j.err
#SBATCH --time=120:00:00
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

# ==============================================================================
# Script: 02_run_braker4_slurm.sh
# Description: Submits the BRAKER4 Snakemake workflow via SLURM
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Load necessary modules (adjust to your HPC)
module load singularity || true

# Environment and Paths
source "$(dirname "$0")/../config.env"
INSTALL_DIR="${VSC_SCRATCH}/software/BRAKER4"
OUT_DIR="${RESULTS_DIR}/braker4"

cd "${OUT_DIR}"

echo "Starting BRAKER4 Pipeline..."

# Activate the Snakemake Conda environment
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate braker_snakemake

# We use Snakemake to manage SLURM jobs from here. The actual Snakemake master process 
# runs on this compute node, and submits jobs to the cluster.
# Note: You can also wrap this in a tmux/screen session and run without sbatch.

snakemake \
    --snakefile "${INSTALL_DIR}/Snakefile" \
    --executor slurm \
    --default-resources slurm_partition=batch mem_mb=64000 \
    --cores 100 \
    --jobs 50 \
    --use-singularity \
    --singularity-prefix .singularity_cache \
    --singularity-args "-B /home -B /user -B /scratch" \
    --keep-going

echo "BRAKER4 Pipeline completed!"
