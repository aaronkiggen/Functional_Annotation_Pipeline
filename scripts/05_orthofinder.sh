#!/bin/bash
#SBATCH --job-name=05_orthofinder
#SBATCH --output=logs/05_orthofinder_%j.out
#SBATCH --error=logs/05_orthofinder_%j.err
#SBATCH --cpus-per-task=36
#SBATCH --mem=128G
#SBATCH --time=15:00:00

################################################################################
# Step 05: OrthoFinder - Phylogenetic Orthology Inference
#
# Description: Identifies orthogroups across multiple species
################################################################################

set -e
set -u
set -o pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.env"

if [ -f "${CONFIG_FILE}" ]; then
    source "${CONFIG_FILE}"
    echo "✓ Loaded configuration from ${CONFIG_FILE}"
else
    echo "ERROR: Configuration file not found: ${CONFIG_FILE}"
    exit 1
fi

################################################################################
# Setup
################################################################################

echo "========================================="
echo "Step 05: OrthoFinder Analysis"
echo "========================================="
echo "Started: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo "CPUs: ${SLURM_CPUS_PER_TASK:-${ORTHOFINDER_CPU}}"
echo "Tree CPUs: ${ORTHOFINDER_TREE_CPU}"
echo ""

# Create output directory
mkdir -p "${ORTHOFINDER_OUTPUT}"
mkdir -p "logs"

# Activate conda environment
if [ -f "${CONDA_INIT:-}" ]; then
    source "${CONDA_INIT}"
fi
conda activate "${ORTHOFINDER_ENV}"

echo "✓ Activated conda environment: ${ORTHOFINDER_ENV}"
echo ""

# Check input directory
ORTHO_INPUT="${PRIMARY_TRANSCRIPTS_DIR}"

if [ ! -d "${ORTHO_INPUT}" ]; then
    echo "ERROR: Input directory not found: ${ORTHO_INPUT}"
    exit 1
fi

# Count input files
NUM_SPECIES=$(find "${ORTHO_INPUT}" -maxdepth 1 -name "*.faa" -o -name "*.fa" -o -name "*.fasta" | wc -l)

if [ ${NUM_SPECIES} -lt 2 ]; then
    echo "ERROR: OrthoFinder requires at least 2 species"
    echo "Found ${NUM_SPECIES} file(s) in ${ORTHO_INPUT}"
    exit 1
fi

echo "Input directory: ${ORTHO_INPUT}"
echo "Number of species: ${NUM_SPECIES}"
echo ""

################################################################################
# Run OrthoFinder
################################################################################

echo "Starting OrthoFinder..."
echo "Search method: ${ORTHOFINDER_SEARCH}"
echo "MSA method: ${ORTHOFINDER_MSA}"
echo "Tree method: ${ORTHOFINDER_TREE}"
echo "MCL inflation: ${ORTHOFINDER_MCL_INFLATION}"
echo ""

orthofinder \
    -f "${ORTHO_INPUT}" \
    -t "${SLURM_CPUS_PER_TASK:-${ORTHOFINDER_CPU}}" \
    -a "${ORTHOFINDER_TREE_CPU}" \
    -S "${ORTHOFINDER_SEARCH}" \
    -M "${ORTHOFINDER_MSA}" \
    -T "${ORTHOFINDER_TREE}" \
    -I "${ORTHOFINDER_MCL_INFLATION}" \
    -o "${ORTHOFINDER_OUTPUT}" \
    -n "${ORTHOFINDER_RUN_NAME}"

################################################################################
# Summary
################################################################################

echo ""
echo "========================================="
echo "OrthoFinder Summary"
echo "========================================="

# Find the results directory (OrthoFinder creates a timestamped subdirectory)
RESULTS_DIR=$(find "${ORTHOFINDER_OUTPUT}" -maxdepth 1 -type d -name "Results_*" | sort | tail -n1)

if [ -d "${RESULTS_DIR}" ]; then
    echo "Results directory: ${RESULTS_DIR}"
    echo ""
    
    # Display statistics if available
    STATS_FILE="${RESULTS_DIR}/Comparative_Genomics_Statistics/Statistics_Overall.tsv"
    if [ -f "${STATS_FILE}" ]; then
        echo "Key Statistics:"
        head -n 20 "${STATS_FILE}"
    fi
    
    echo ""
    echo "Output files:"
    ls -lh "${RESULTS_DIR}/Orthogroups/" 2>/dev/null | head -n 10
else
    echo "WARNING: Results directory not found"
fi

echo ""
echo "Completed: $(date)"
echo "========================================="

exit 0
