#!/bin/bash
#SBATCH --job-name=orthofinder
#SBATCH --output=logs/orthofinder_%j.out
#SBATCH --error=logs/orthofinder_%j.err
#SBATCH --time=48:00:00
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G

# ==============================================================================
# Script: 02b_run_orthofinder.sh
# Description: Gathers the primary transcript protein files compiled by BRAKER4
#              and subsequently submits them to OrthoFinder for comparative
#              genomics and ortholog group calculations.
# ==============================================================================

set -e

# Load OrthoFinder conda environment
# Adjust this line if you use module load on your HPC
source "${HOME}/software/miniconda3/bin/activate" orthofinder || echo "Assuming orthofinder is in path"

source "$(dirname "$0")/../config.env"
BRAKER_OUT_DIR="${RESULTS_DIR}/braker4/output"
ORTHO_INPUT_DIR="${RESULTS_DIR}/orthofinder/input_proteins"

mkdir -p "${ORTHO_INPUT_DIR}"

echo "=================================================="
echo "    Gathering BRAKER4 Proteomes for OrthoFinder   "
echo "=================================================="

# Wait! We only want to run OrthoFinder on one definitive structural
# annotation per species (as requested, the protein-only _prot baseline).
# Running OrthoFinder on both prot-only AND varsus simultaneously treats them 
# as separate species on a phylogenetic tree, which pollutes the results!
# We will explicitly match '*_prot' directories.
for SAMPLE_DIR in "${BRAKER_OUT_DIR}"/*_prot; do
    if [ -d "${SAMPLE_DIR}" ]; then
        SAMPLE_NAME=$(basename "${SAMPLE_DIR}" | sed 's/_prot//')
        PROTEIN_FILE="${SAMPLE_DIR}/braker.aa"

        if [ -f "${PROTEIN_FILE}" ]; then
            echo "Symlinking ${SAMPLE_NAME} proteome..."
            ln -sf "${PROTEIN_FILE}" "${ORTHO_INPUT_DIR}/${SAMPLE_NAME}.faa"
        fi
    fi
done

echo "=================================================="
echo "               Running OrthoFinder                "
echo "=================================================="
orthofinder -f "${ORTHO_INPUT_DIR}" -t 32 -a 32 -M msa

echo "OrthoFinder completed successfully!"