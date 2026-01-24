#!/bin/bash
#SBATCH --job-name=04_eggnog_v5
#SBATCH --output=logs/04_eggnog_%j.out
#SBATCH --error=logs/04_eggnog_%j.err
#SBATCH --time=4:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=20

################################################################################
# Step 04: EggNOG-mapper V5 - Functional Annotation
#
# Description: Traditional EggNOG-mapper (version 5) annotation
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
echo "Step 04: EggNOG-mapper V5 Annotation"
echo "========================================="
echo "Started: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo ""

# Create directories
EGGNOG_V5_OUTPUT="${EGGNOG_OUTPUT}/v5"
mkdir -p "${EGGNOG_V5_OUTPUT}"
mkdir -p "${TMP_DIR}/eggnog"
mkdir -p "logs"

# Activate conda environment
if [ -f "${CONDA_INIT:-}" ]; then
    source "${CONDA_INIT}"
fi

# Use EGGNOG_ENV if defined in config
if [ -n "${EGGNOG_ENV:-}" ]; then
    conda activate "${EGGNOG_ENV}"
    echo "✓ Activated conda environment: ${EGGNOG_ENV}"
fi

# Set EggNOG data directory
export EGGNOG_DATA_DIR="${DB_ROOT}/eggnog"

echo "✓ Database: ${EGGNOG_DATA_DIR}"
echo ""

################################################################################
# Process Files
################################################################################

INPUT_FILES=($(find "${PRIMARY_TRANSCRIPTS_DIR}" -maxdepth 1 -name "${INPUT_PATTERN}" -type f))

if [ ${#INPUT_FILES[@]} -eq 0 ]; then
    echo "ERROR: No input files found in ${PRIMARY_TRANSCRIPTS_DIR}"
    exit 1
fi

echo "Found ${#INPUT_FILES[@]} input file(s)"
echo ""

PROCESSED=0
FAILED=0

for INPUT_FILE in "${INPUT_FILES[@]}"; do
    BASENAME=$(basename "${INPUT_FILE}")
    SAMPLE="${BASENAME%.*}"
    
    echo "----------------------------------------"
    echo "Processing: ${SAMPLE}"
    echo "----------------------------------------"
    
    SAMPLE_OUTPUT="${EGGNOG_V5_OUTPUT}/${SAMPLE}"
    SAMPLE_TMP="${TMP_DIR}/eggnog/${SAMPLE}_${SLURM_JOB_ID}"
    
    mkdir -p "${SAMPLE_TMP}"
    
    # Run EggNOG-mapper
    if emapper.py \
        -m diamond \
        --cpu "${SLURM_CPUS_PER_TASK}" \
        -i "${INPUT_FILE}" \
        --itype proteins \
        --data_dir "${EGGNOG_DATA_DIR}" \
        --tax_scope Arthropoda \
        --report_orthologs \
        --output "${SAMPLE}_emapper" \
        --output_dir "${SAMPLE_OUTPUT}" \
        --go_evidence all \
        --excel \
        --temp_dir "${SAMPLE_TMP}" \
        --override \
        --decorate_gff yes; then
        
        echo "✓ Completed: ${SAMPLE}"
        ((PROCESSED++))
        
        # Cleanup temp
        rm -rf "${SAMPLE_TMP}"
    else
        echo "✗ Failed: ${SAMPLE}"
        ((FAILED++))
    fi
    echo ""
done

################################################################################
# Summary
################################################################################

echo "========================================="
echo "Summary"
echo "========================================="
echo "Processed: ${PROCESSED}"
echo "Failed: ${FAILED}"
echo "Output directory: ${EGGNOG_V5_OUTPUT}"
echo "Completed: $(date)"
echo "========================================="

[ ${FAILED} -gt 0 ] && exit 1
exit 0
