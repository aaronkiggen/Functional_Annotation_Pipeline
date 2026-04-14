#!/bin/bash
#SBATCH --job-name=func_integration
#SBATCH --output=logs/integration_%j.out
#SBATCH --error=logs/integration_%j.err
#SBATCH --time=04:00:00
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

# ==============================================================================
# Script: 06_run_step3_integration.sh
# Description: Generates final unified outputs. Combines BRAKER4 comparative 
#              stats, GO term QC metrics, and the heavily compiled Excel DataFrames
#              spanning classical markers + FANTASIA ML predictions.
# ==============================================================================

set -e

# Base Paths
source "$(dirname "$0")/../config.env"
PIPELINE_DIR="${PROJECT_ROOT}"
RESULTS_DIR="${PIPELINE_DIR}/results"
BRAKER_DIR="${RESULTS_DIR}/braker4/output"
FUNC_DIR="${RESULTS_DIR}/functional"
INTEGRATION_DIR="${RESULTS_DIR}/integration_excel"

mkdir -p "${INTEGRATION_DIR}"

echo "=================================================="
echo "    Step 3.1: Running Base Integration Tables     "
echo "=================================================="
# We use the updated create_excel_outputs.py script which natively detects
# braker.gff3 to extract FANTASIA embeddings along with the classical tools!

python3 "${PIPELINE_DIR}/scripts/INTEGRATION/create_excel_outputs.py" \
    --results-dir "${RESULTS_DIR}" \
    --output-dir "${INTEGRATION_DIR}"

echo "=================================================="
echo "    Step 3.2: Formatting FANTASIA Gene Offsets    "
echo "=================================================="
# Not actively required as a manual step anymore if FANTASIA runs natively 
# in BRAKER4 with min_score=0.5. However, filtering can remain if offline 
# TSVs were dumped.

echo "=================================================="
echo "    Step 3.3: Running Complete GO QC Metrics      "
echo "=================================================="
# For every species processed, loop and align standard vs model GO arrays
# using Semantic Wang Mapping. (EggNOG + IPS vs Fantasia)
for SAMPLE_DIR in "${BRAKER_DIR}"/*; do
    if [ -d "${SAMPLE_DIR}" ]; then
        SAMPLE_NAME=$(basename "${SAMPLE_DIR}")
        BRAKER_GFF="${SAMPLE_DIR}/braker.gff3"
        EGGNOG_ANNO="${FUNC_DIR}/eggnog/${SAMPLE_NAME}.emapper.annotations"
        IPS_TSV="${FUNC_DIR}/interproscan/${SAMPLE_NAME}.tsv"
        
        OUT_EXCEL="${INTEGRATION_DIR}/${SAMPLE_NAME}_GO_Semantic_QC.xlsx"
        
        if [ -f "${BRAKER_GFF}" ] && [ -f "${EGGNOG_ANNO}" ] && [ -f "${IPS_TSV}" ]; then
            echo "Computing Wang Semantic Similarities for ${SAMPLE_NAME}..."
            Rscript "${PIPELINE_DIR}/scripts/05_step3_gosemsim_metrics.R" \
                --eggnog "${EGGNOG_ANNO}" \
                --ips "${IPS_TSV}" \
                --output "${OUT_EXCEL}"
        else
            echo "Skipping QC for ${SAMPLE_NAME} - missing functional results."
        fi
    fi
done

echo "=================================================="
echo "         INTEGRATION PIPELINE COMPLETE            "
echo "=================================================="
echo "Final unified gene annotations and semantic QC tables inside:"
echo "${INTEGRATION_DIR}"
