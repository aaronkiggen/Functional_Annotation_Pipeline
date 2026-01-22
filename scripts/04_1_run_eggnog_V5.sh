#!/bin/bash
#SBATCH --job-name=04_eggnog
#SBATCH --time=4:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=20
#SBATCH -A lp_svbelleghem
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

source ../config.env
source "${CONDA_SOURCE}"
conda activate "${ENV_EGGNOG}"

export EGGNOG_DATA_DIR="${EGGNOG_DB}"

SPECIES="LRV01"
INPUT_FAA="${INPUT_DIR}/${SPECIES}/primary_transcripts/GCA_030254905.1_UOB_LRV0_1_protein.faa"
RESULT_DIR="${OUTPUT_DIR}/eggnog/${SPECIES}"
TEMP_DIR="${PROJECT_BASE}/tmp/eggnog_${SLURM_JOB_ID}"

mkdir -p "${RESULT_DIR}" "${TEMP_DIR}"

echo "[INFO] Running EggNOG for ${SPECIES}"

"${EGGNOG_EMAPPER}" \
    -m diamond --cpu "${SLURM_CPUS_PER_TASK}" \
    -i "${INPUT_FAA}" \
    --itype proteins \
    --data_dir "${EGGNOG_DB}" \
    --tax_scope Arthropoda \
    --report_orthologs \
    --output "${SPECIES}_emapper" \
    --output_dir "${RESULT_DIR}" \
    --go_evidence all \
    --excel \
    --temp_dir "${TEMP_DIR}" \
    --override --decorate_gff yes

echo "[DONE] EggNOG complete."
