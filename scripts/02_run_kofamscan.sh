#!/bin/bash
#SBATCH --job-name=02_kofamscan
#SBATCH --output=logs/02_kofam_%j.out
#SBATCH --error=logs/02_kofam_%j.err
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32GB
#SBATCH --partition=cpu

################################################################################
# Step 02: KofamScan - KEGG Orthology Annotation
#
# Description: Uses profile HMMs to assign KEGG Ortholog identifiers
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
echo "Step 02: KofamScan Annotation"
echo "========================================="
echo "Started: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo "CPUs: ${SLURM_CPUS_PER_TASK:-${KOFAM_CPU}}"
echo ""

# Create directories
mkdir -p "${KOFAM_OUTPUT}"
mkdir -p "${KOFAM_TMP_DIR}"
mkdir -p "logs"

# Activate conda environment
if [ -f "${CONDA_INIT:-}" ]; then
    source "${CONDA_INIT}"
fi
conda activate "${KOFAM_ENV}"

echo "✓ Activated conda environment: ${KOFAM_ENV}"

# Check database
if [ ! -d "${KOFAM_PROFILES}" ]; then
    echo "ERROR: KofamScan profiles not found: ${KOFAM_PROFILES}"
    exit 1
fi

if [ ! -f "${KOFAM_KO_LIST}" ]; then
    echo "ERROR: KO list not found: ${KOFAM_KO_LIST}"
    exit 1
fi

echo "✓ Database: ${KOFAM_DB}"
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
    
    OUTPUT_FILE="${KOFAM_OUTPUT}/${SAMPLE}_kofam_mapper.tsv"
    
    # Run KofamScan
    if exec_annotation \
        -p "${KOFAM_PROFILES}" \
        -k "${KOFAM_KO_LIST}" \
        -f mapper \
        -o "${OUTPUT_FILE}" \
        --cpu="${SLURM_CPUS_PER_TASK:-${KOFAM_CPU}}" \
        --tmp-dir="${KOFAM_TMP_DIR}" \
        "${INPUT_FILE}"; then
        
        # Count annotations
        ANNOT_COUNT=$(grep -v "^#" "${OUTPUT_FILE}" | wc -l || echo "0")
        echo "✓ Annotations: ${ANNOT_COUNT}"
        echo "  Output: ${OUTPUT_FILE}"
        ((PROCESSED++))
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
echo "Output directory: ${KOFAM_OUTPUT}"
echo "Completed: $(date)"
echo "========================================="

[ ${FAILED} -gt 0 ] && exit 1
exit 0
