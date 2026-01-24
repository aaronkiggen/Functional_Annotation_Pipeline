#!/bin/bash
#SBATCH --job-name=03_interproscan
#SBATCH --output=logs/03_interpro_%j.out
#SBATCH --error=logs/03_interpro_%j.err
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=4g
#SBATCH --time=07:00:00

################################################################################
# Step 03: InterProScan - Domain and Motif Analysis
#
# Description: Comprehensive protein domain and motif annotation
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
echo "Step 03: InterProScan Annotation"
echo "========================================="
echo "Started: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo "CPUs: ${SLURM_CPUS_PER_TASK:-${INTERPROSCAN_CPU}}"
echo "Memory: ${INTERPROSCAN_MEMORY}GB"
echo ""

# Create directories
mkdir -p "${INTERPROSCAN_OUTPUT}"
mkdir -p "${INTERPROSCAN_TMP_DIR}"
mkdir -p "logs"

# Load modules
if command -v module &> /dev/null; then
    module load ${MODULE_PYTHON} || true
    module load Perl/5.40.0-GCCcore-14.2.0 || true
    module load ${MODULE_JAVA} || true
    echo "✓ Modules loaded"
fi

# Check InterProScan installation
if [ ! -d "${INTERPROSCAN_HOME}" ]; then
    echo "ERROR: InterProScan not found: ${INTERPROSCAN_HOME}"
    exit 1
fi

INTERPRO_SCRIPT="${INTERPROSCAN_HOME}/interproscan.sh"

if [ ! -f "${INTERPRO_SCRIPT}" ]; then
    echo "ERROR: interproscan.sh not found in ${INTERPROSCAN_HOME}"
    exit 1
fi

echo "✓ InterProScan: ${INTERPROSCAN_HOME}"

# Set Java options
export _JAVA_OPTIONS="${INTERPROSCAN_JAVA_OPTS}"

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
    
    # Build InterProScan command
    CMD="${INTERPRO_SCRIPT} \
        -i ${INPUT_FILE} \
        -t p \
        -b ${INTERPROSCAN_OUTPUT}/${SAMPLE} \
        --cpu ${SLURM_CPUS_PER_TASK:-${INTERPROSCAN_CPU}} \
        -T ${INTERPROSCAN_TMP_DIR} \
        -f ${INTERPROSCAN_FORMATS}"
    
    # Add optional flags
    [ "${INTERPROSCAN_GOTERMS}" = "true" ] && CMD="${CMD} -goterms"
    [ "${INTERPROSCAN_IPRLOOKUP}" = "true" ] && CMD="${CMD} -iprlookup"
    [ "${INTERPROSCAN_PATHWAYS}" = "true" ] && CMD="${CMD} -pa"
    [ -n "${INTERPROSCAN_APPL}" ] && CMD="${CMD} -appl ${INTERPROSCAN_APPL}"
    
    echo "Command: ${CMD}"
    echo ""
    
    # Run InterProScan
    if ${CMD}; then
        echo "✓ Completed: ${SAMPLE}"
        ((PROCESSED++))
    else
        echo "✗ Failed: ${SAMPLE}"
        ((FAILED++))
    fi
    echo ""
done

# Cleanup temp directory
if [ "${CLEANUP_TMP:-true}" = "true" ]; then
    echo "Cleaning up temporary files..."
    rm -rf "${INTERPROSCAN_TMP_DIR}"
fi

################################################################################
# Summary
################################################################################

echo "========================================="
echo "Summary"
echo "========================================="
echo "Processed: ${PROCESSED}"
echo "Failed: ${FAILED}"
echo "Output directory: ${INTERPROSCAN_OUTPUT}"
echo "Completed: $(date)"
echo "========================================="

[ ${FAILED} -gt 0 ] && exit 1
exit 0
