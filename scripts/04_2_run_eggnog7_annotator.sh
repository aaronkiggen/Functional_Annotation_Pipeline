#!/bin/bash
#SBATCH --job-name=eggnog7
#SBATCH --output=logs/eggnog7_%j. out
#SBATCH --error=logs/eggnog7_%j.err
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64GB
#SBATCH --partition=cpu

################################################################################
# EggNOG 7 Functional Annotation using Diamond BLASTP
# 
# Description: Two-step annotation workflow
#   1. Diamond BLASTP against EggNOG 7 database
#   2. Merge hits with EggNOG master table

################################################################################


################################################################################
# Configuration Variables
################################################################################

# Input/Output directories
INPUT_DIR="${INPUT_DIR:-../primary_transcripts}"
OUTPUT_DIR="${OUTPUT_DIR:-../results/eggnog7}"
LOG_DIR="${LOG_DIR:-../logs}"

# EggNOG 7 database paths (UPDATE THESE!)
EGGNOG_DIAMOND_DB="${EGGNOG_DIAMOND_DB:-${HOME}/databases/eggnog7/eggnog7_20251223_proteins.dmnd}"
EGGNOG_MASTER_TABLE="${EGGNOG_MASTER_TABLE:-${HOME}/databases/eggnog7/eggnog7_20251223_master_search_table.tsv.gz}"

# Annotation script path
EGGNOG7_SCRIPT="${EGGNOG7_SCRIPT:-${SCRIPT_DIR}/../tools/eggnog7_annotator.sh}"

# Diamond parameters
THREADS="${SLURM_CPUS_PER_TASK:-32}"
EVALUE="${EVALUE:-1e-5}"
KEEP_DIAMOND="${KEEP_DIAMOND:-false}"  # Set to "true" to keep intermediate files

# Sample name (can be overridden)
SAMPLE_NAME="${SAMPLE_NAME:-$(basename ${INPUT_DIR})}"

# Input file pattern
INPUT_PATTERN="${INPUT_PATTERN:-*.faa}"

################################################################################
# Setup
################################################################################

echo "========================================="
echo "EggNOG 7 Annotation - Job ${SLURM_JOB_ID}"
echo "========================================="
echo "Started: $(date)"

# Create directories
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${LOG_DIR}"


# Make script executable
chmod +x "${EGGNOG7_SCRIPT}"

# Check database files
echo "Checking database files..."
if [ ! -f "${EGGNOG_DIAMOND_DB}" ]; then
    echo "ERROR:  Diamond database not found: ${EGGNOG_DIAMOND_DB}"
    echo "Please download it from the EggNOG database."
    exit 1
fi

if [ ! -f "${EGGNOG_MASTER_TABLE}" ]; then
    echo "ERROR: Master table not found: ${EGGNOG_MASTER_TABLE}"
    echo "Please download it from the EggNOG database."
    exit 1
fi

echo "✓ Diamond database:  ${EGGNOG_DIAMOND_DB}"
echo "✓ Master table: ${EGGNOG_MASTER_TABLE}"
echo ""


################################################################################
# Process input files
################################################################################

echo "========================================="
echo "Processing Input Files"
echo "========================================="

# Find input files
INPUT_FILES=($(find "${INPUT_DIR}" -maxdepth 1 -name "${INPUT_PATTERN}" -type f))

if [ ${#INPUT_FILES[@]} -eq 0 ]; then
    echo "ERROR: No input files found matching pattern:  ${INPUT_DIR}/${INPUT_PATTERN}"
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

# Counter for statistics
TOTAL_FILES=${#INPUT_FILES[@]}
PROCESSED=0
FAILED=0

for INPUT_FILE in "${INPUT_FILES[@]}"; do
    
    # Extract sample name from filename
    BASENAME=$(basename "${INPUT_FILE}")
    SAMPLE="${BASENAME%.*}"
    
    echo "========================================="
    echo "Processing: ${SAMPLE}"
    echo "========================================="
    echo "Input: ${INPUT_FILE}"
    echo "Sample name: ${SAMPLE}"
    echo ""
    
    # Count sequences
    SEQ_COUNT=$(grep -c "^>" "${INPUT_FILE}" || echo "0")
    echo "Sequences: ${SEQ_COUNT}"
    
    if [ ${SEQ_COUNT} -eq 0 ]; then
        echo "⚠ Warning: No sequences found in ${INPUT_FILE}, skipping..."
        ((FAILED++))
        continue
    fi
    
    # Build command
    CMD="${EGGNOG7_SCRIPT} \
        -d ${EGGNOG_DIAMOND_DB} \
        -q ${INPUT_FILE} \
        -m ${EGGNOG_MASTER_TABLE} \
        -s ${SAMPLE} \
        -o ${OUTPUT_DIR} \
        -e ${EVALUE} \
        -p ${THREADS}"
    
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
echo "Total files:  ${TOTAL_FILES}"
echo "Successfully processed: ${PROCESSED}"
echo "Failed: ${FAILED}"
echo ""
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# List output files
if [ ${PROCESSED} -gt 0 ]; then
    echo "Generated files:"
    ls -lh "${OUTPUT_DIR}"/*.eggnog.tsv.gz 2>/dev/null || echo "  (none)"
fi

echo ""
echo "Completed: $(date)"
echo "========================================="

# Exit with error if any files failed
if [ ${FAILED} -gt 0 ]; then
    echo "⚠ Warning: ${FAILED} file(s) failed to process"
    exit 1
fi

echo "✓ All files processed successfully!"
exit 0
