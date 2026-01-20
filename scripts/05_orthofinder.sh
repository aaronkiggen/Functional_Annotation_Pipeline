#!/bin/bash -l
#SBATCH --job-name=05_orthofinder
#SBATCH --cpus-per-task=36
#SBATCH --mem=128G
#SBATCH --time=15:00:00
#SBATCH -A lp_svbelleghem
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

source ../config.env
source "${CONDA_SOURCE}"
conda activate "${ENV_ORTHOFINDER}"

# Note: Orthofinder takes a directory of FASTA files, not a single file
ORTHO_INPUT="${INPUT_DIR}/all_species_proteomes/"
ORTHO_OUTPUT="${OUTPUT_DIR}/orthofinder_results/"

echo "[INFO] Starting OrthoFinder with ${SLURM_CPUS_PER_TASK} threads"

orthofinder \
    -f "${ORTHO_INPUT}" \
    -t "${SLURM_CPUS_PER_TASK}" \
    -a "${SLURM_CPUS_PER_TASK}" \
    -o "${ORTHO_OUTPUT}"

echo "[DONE] OrthoFinder complete."
