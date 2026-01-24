#!/bin/bash
#SBATCH --job-name=01_extract_isoform
#SBATCH --output=logs/01_extract_%j.out
#SBATCH --error=logs/01_extract_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=02:00:00
#SBATCH --partition=cpu

################################################################################
# Step 01: Extract Longest Isoforms
#
# Description: Filters protein FASTA files to retain only the longest
#              transcript per gene, reducing redundancy for downstream analysis
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

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
# Configuration
################################################################################

# Helper script location
HELPER_SCRIPT="${SCRIPT_DIR}/helper/primary_transcript.py"

# Override from config.env
INPUT_DIR="${INPUT_DIR:-../input_proteomes}"
OUTPUT_DIR="${STEP01_OUTPUT:-../primary_transcripts}"
INPUT_PATTERN="${INPUT_PATTERN:-*.faa}"
MIN_LENGTH="${MIN_SEQ_LENGTH:-50}"

################################################################################
# Setup
################################################################################

echo "========================================="
echo "Step 01: Extract Longest Isoforms"
echo "========================================="
echo "Started: $(date)"
echo "Host: $(hostname)"
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}"
mkdir -p "logs"

# Check helper script exists
if [ ! -f "${HELPER_SCRIPT}" ]; then
    echo "ERROR: Helper script not found: ${HELPER_SCRIPT}"
    echo "Please ensure primary_transcript.py exists in scripts/helper/"
    exit 1
fi

# Activate Python environment if specified
if [ -n "${PYTHON_ENV:-}" ] && [ "${PYTHON_ENV}" != "base" ]; then
    echo "Activating conda environment: ${PYTHON_ENV}"
    if [ -f "${CONDA_INIT:-}" ]; then
        source "${CONDA_INIT}"
    fi
    conda activate "${PYTHON_ENV}"
fi

################################################################################
# Process Files
################################################################################

# Find input files
INPUT_FILES=($(find "${INPUT_DIR}" -maxdepth 1 -name "${INPUT_PATTERN}" -type f))

if [ ${#INPUT_FILES[@]} -eq 0 ]; then
    echo "ERROR: No input files found matching: ${INPUT_DIR}/${INPUT_PATTERN}"
    exit 1
fi

echo "Found ${#INPUT_FILES[@]} input file(s):"
for file in "${INPUT_FILES[@]}"; do
    echo "  - $(basename ${file})"
done
echo ""

# Process each file
PROCESSED=0
FAILED=0

for INPUT_FILE in "${INPUT_FILES[@]}"; do
    BASENAME=$(basename "${INPUT_FILE}")
    SAMPLE="${BASENAME%.*}"
    
    echo "----------------------------------------"
    echo "Processing: ${SAMPLE}"
    echo "----------------------------------------"
    
    # Count input sequences
    INPUT_COUNT=$(grep -c "^>" "${INPUT_FILE}" || echo "0")
    echo "Input sequences: ${INPUT_COUNT}"
    
    if [ ${INPUT_COUNT} -eq 0 ]; then
        echo "⚠ Warning: No sequences found, skipping..."
        ((FAILED++))
        continue
    fi
    
    # Run extraction
    OUTPUT_FILE="${OUTPUT_DIR}/${BASENAME}"
    
    if python "${HELPER_SCRIPT}" "${INPUT_FILE}" "${OUTPUT_FILE}" --min-length "${MIN_LENGTH}"; then
        # Count output sequences
        OUTPUT_COUNT=$(grep -c "^>" "${OUTPUT_FILE}" || echo "0")
        REDUCTION=$(awk "BEGIN {printf \"%.1f\", ((${INPUT_COUNT}-${OUTPUT_COUNT})/${INPUT_COUNT})*100}")
        
        echo "✓ Output sequences: ${OUTPUT_COUNT}"
        echo "  Reduction: ${REDUCTION}%"
        echo "  Output: ${OUTPUT_FILE}"
        ((PROCESSED++))
    else
        echo "✗ Failed to process ${SAMPLE}"
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
echo "Total files: ${#INPUT_FILES[@]}"
echo "Processed: ${PROCESSED}"
echo "Failed: ${FAILED}"
echo "Output directory: ${OUTPUT_DIR}"
echo ""
echo "Completed: $(date)"
echo "========================================="

[ ${FAILED} -gt 0 ] && exit 1
exit 0
