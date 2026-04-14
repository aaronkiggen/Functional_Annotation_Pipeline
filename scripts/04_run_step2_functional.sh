#!/bin/bash
#SBATCH --job-name=func_annot_master
#SBATCH --output=logs/func_master_%j.out
#SBATCH --error=logs/func_master_%j.err
#SBATCH --time=02:00:00
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G

# ==============================================================================
# Script: 04_run_step2_functional.sh
# Description: Detects all successful BRAKER4 protein outputs and submits
#              EggNOG, InterProScan, and KofamScan jobs automatically.
# ==============================================================================

set -e

source "$(dirname "$0")/../config.env"
BRAKER_OUT_DIR="${RESULTS_DIR}/braker4/output"
FUNC_OUT_DIR="${RESULTS_DIR}/functional"

mkdir -p "${FUNC_OUT_DIR}/eggnog"
mkdir -p "${FUNC_OUT_DIR}/interproscan"
mkdir -p "${FUNC_OUT_DIR}/kofamscan"

echo "========================================="
echo "   Submitting Functional Annotations     "
echo "========================================="

# Loop through all sample directories in BRAKER4 output
for SAMPLE_DIR in "${BRAKER_OUT_DIR}"/*; do
    if [ -d "${SAMPLE_DIR}" ]; then
        SAMPLE_NAME=$(basename "${SAMPLE_DIR}")
        PROTEIN_FILE="${SAMPLE_DIR}/braker.aa"

        if [ -f "${PROTEIN_FILE}" ]; then
            echo "Found protein FASTA for ${SAMPLE_NAME}. Submitting jobs..."

            # 1. Submit EggNOG job
            sbatch --job-name="egg_${SAMPLE_NAME}" \
                   --output="logs/egg_${SAMPLE_NAME}_%j.out" \
                   --wrap="singularity exec -B /user /path/to/eggnog_container.sif emapper.py -m diamond -i ${PROTEIN_FILE} -o ${FUNC_OUT_DIR}/eggnog/${SAMPLE_NAME} --cpu 16" \
                   --cpus-per-task=16 --mem=32G

            # 2. Submit InterProScan job
            sbatch --job-name="ips_${SAMPLE_NAME}" \
                   --output="logs/ips_${SAMPLE_NAME}_%j.out" \
                   --wrap="/path/to/interproscan/interproscan.sh -i ${PROTEIN_FILE} -f TSV -goterms -pa -d ${FUNC_OUT_DIR}/interproscan/${SAMPLE_NAME} -cpu 16" \
                   --cpus-per-task=16 --mem=32G

            # 3. Submit KofamScan job
            sbatch --job-name="kof_${SAMPLE_NAME}" \
                   --output="logs/kof_${SAMPLE_NAME}_%j.out" \
                   --wrap="/path/to/kofamscan/exec_annotation -o ${FUNC_OUT_DIR}/kofamscan/${SAMPLE_NAME}_kofam.txt ${PROTEIN_FILE} --cpu 16" \
                   --cpus-per-task=16 --mem=16G

        else
            echo "Warning: No braker.aa found in ${SAMPLE_DIR}"
        fi
    fi
done

echo "All functional annotation jobs submitted to SLURM!"
