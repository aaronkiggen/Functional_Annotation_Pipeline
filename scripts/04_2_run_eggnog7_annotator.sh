#!/bin/bash
#SBATCH --job-name=04_eggnog7
#SBATCH --output=logs/04_eggnog7_%j.out
#SBATCH --error=logs/04_eggnog7_%j.err
#SBATCH --time=06:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64GB
#SBATCH --partition=cpu

################################################################################
# Step 04: EggNOG 7 Functional Annotation using Diamond BLASTP
#
# Description: Two-step annotation workflow
#   1. Diamond BLASTP against EggNOG 7 database
#   2. Merge hits with EggNOG master table
################################################################################


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
echo "EggNOG 7 Annotation - Job ${SLURM_JOB_ID}"
echo "========================================="
echo "Started: $(date)"
echo "Host: $(hostname)"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory: ${SLURM_MEM_PER_NODE:-N/A} MB"
echo ""

# Create directories
mkdir -p "${EGGNOG_OUTPUT}"
mkdir -p "${LOG_DIR}"

# EggNOG 7 annotator script location
EGGNOG7_SCRIPT="${SCRIPT_DIR}/eggnog7_annotator/eggnog7_annotator_AK.sh"

# Check if annotation script exists
if [ ! -f "${EGGNOG7_SCRIPT}" ]; then
    echo "ERROR: EggNOG 7 annotation script not found: ${EGGNOG7_SCRIPT}"
    echo "Please ensure eggnog7_annotator.sh is in the correct location."
    exit 1
fi

# Make script executable
chmod +x "${EGGNOG7_SCRIPT}"

# Check database files
echo "Checking database files..."
if [ ! -f "${EGGNOG_DIAMOND_DB}" ]; then
    echo "ERROR: Diamond database not found: ${EGGNOG_DIAMOND_DB}"
    exit 1
fi

if [ ! -f "${EGGNOG_MASTER_TABLE}" ]; then
    echo "ERROR: Master table not found: ${EGGNOG_MASTER_TABLE}"
    exit 1
fi

echo "✓ Diamond database: ${EGGNOG_DIAMOND_DB}"
echo "✓ Master table: ${EGGNOG_MASTER_TABLE}"
echo ""

# Add eggnog7_annotator to PATH
ANNOTATOR_DIR="${SCRIPT_DIR}/eggnog7_annotator"
if [ -d "${ANNOTATOR_DIR}" ]; then
    export PATH="${ANNOTATOR_DIR}:$PATH"
    echo "✓ Added eggnog7_annotator to PATH: ${ANNOTATOR_DIR}"
else
    echo "ERROR: eggnog7_annotator directory not found: ${ANNOTATOR_DIR}"
    exit 1
fi
echo ""

# Load Diamond module
if command -v module &> /dev/null && [ -n "${EGGNOG_MODULE:-}" ]; then
    echo "Loading module: ${EGGNOG_MODULE}"
    module load "${EGGNOG_MODULE}"
    module list
fi

# Verify Diamond is available
if ! command -v diamond &> /dev/null; then
    echo "ERROR: Diamond not found in PATH"
    exit 1
fi

DIAMOND_VERSION=$(diamond version 2>&1 | head -n1)
echo "✓ Diamond version: ${DIAMOND_VERSION}"
echo ""

################################################################################
# Process input files
################################################################################

echo "========================================="
echo "Processing Input Files"
echo "========================================="

INPUT_FILES=($(find "${PRIMARY_TRANSCRIPTS_DIR}" -maxdepth 1 -name "${INPUT_PATTERN}" -type f))

if [ ${#INPUT_FILES[@]} -eq 0 ]; then
    echo "ERROR: No input files found matching pattern: ${PRIMARY_TRANSCRIPTS_DIR}/${INPUT_PATTERN}"
    exit 1
fi

echo "Found ${#INPUT_FILES[@]} input file(s):"
for file in "${INPUT_FILES[@]}"; do
    echo "  - $(basename ${file})"
done
echo ""

################################################################################
# Run EggNOG 7 annotation
################################################################################

TOTAL_FILES=${#INPUT_FILES[@]}
PROCESSED=0
FAILED=0

for INPUT_FILE in "${INPUT_FILES[@]}"; do
    
    BASENAME=$(basename "${INPUT_FILE}")
    SAMPLE="${BASENAME%.*}"
    
    echo "========================================="
    echo "Processing: ${SAMPLE}"
    echo "========================================="
    echo "Input: ${INPUT_FILE}"
    echo ""
    
    # Count sequences
    SEQ_COUNT=$(grep -c "^>" "${INPUT_FILE}" || echo "0")
    echo "Sequences: ${SEQ_COUNT}"
    
    if [ ${SEQ_COUNT} -eq 0 ]; then
        echo "⚠ Warning: No sequences found, skipping..."
        ((FAILED++))
        continue
    fi
    
    # Build command
    CMD="${EGGNOG7_SCRIPT} \
        -d ${EGGNOG_DIAMOND_DB} \
        -q ${INPUT_FILE} \
        -m ${EGGNOG_MASTER_TABLE} \
        -s ${SAMPLE} \
        -o ${EGGNOG_OUTPUT} \
        -e ${EGGNOG_EVALUE} \
        -p ${SLURM_CPUS_PER_TASK}"
    
    # Add --keep-diamond flag if requested
    if [ "${KEEP_DIAMOND}" = "true" ]; then
        CMD="${CMD} --keep-diamond"
    fi
    
    echo "Command:"
    echo "${CMD}"
    echo ""
    
    # Execute annotation
    START_TIME=$(date +%s)
    
    if ${CMD}; then
        END_TIME=$(date +%s)
        ELAPSED=$((END_TIME - START_TIME))
        
        echo ""
        echo "✓ Completed: ${SAMPLE}"
        echo "  Runtime: ${ELAPSED} seconds"
        
        # Check output
        OUTPUT_FILE="${EGGNOG_OUTPUT}/${SAMPLE}.eggnog.tsv.gz"
        if [ -f "${OUTPUT_FILE}" ]; then
            OUTPUT_SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)
            echo "  Output: ${OUTPUT_FILE} (${OUTPUT_SIZE})"
            
            # Count annotations
            ANNOT_COUNT=$(zcat "${OUTPUT_FILE}" | grep -v "^#" | wc -l || echo "0")
            echo "  Annotations: ${ANNOT_COUNT}"
            
            # Calculate coverage
            if [ ${SEQ_COUNT} -gt 0 ]; then
                COVERAGE=$(awk "BEGIN {printf \"%.1f\", (${ANNOT_COUNT}/${SEQ_COUNT})*100}")
                echo "  Coverage: ${COVERAGE}%"
            fi
        fi
        
        ((PROCESSED++))
    else
        echo ""
        echo "✗ Failed: ${SAMPLE}"
        ((FAILED++))
    fi
    
    echo ""
done

################################################################################
# Summary
################################################################################

echo "========================================="
echo "EggNOG 7 Annotation Summary"
echo "========================================="
echo "Total files: ${TOTAL_FILES}"
echo "Successfully processed: ${PROCESSED}"
echo "Failed: ${FAILED}"
echo ""
echo "Output directory: ${EGGNOG_OUTPUT}"
echo ""

if [ ${PROCESSED} -gt 0 ]; then
    echo "Generated files:"
    ls -lh "${EGGNOG_OUTPUT}"/*.eggnog.tsv.gz 2>/dev/null || echo "  (none)"
fi

echo ""
echo "Completed: $(date)"
echo "========================================="

[ ${FAILED} -gt 0 ] && exit 1
echo "✓ All files processed successfully!"
exit 0
