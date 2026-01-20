#!/bin/bash -l
#SBATCH --job-name=03_interpro
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=4g
#SBATCH --time=07:00:00
#SBATCH -A lp_svbelleghem
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

source ../config.env

# Load Modules (Adjust versions as needed)
module load Python/3.13.1-GCCcore-14.2.0
module load Perl/5.40.0-GCCcore-14.2.0
module load Java/17.0.15

SPECIES="LRV01"
INPUT_FAA="${INPUT_DIR}/${SPECIES}/primary_transcripts/GCA_030254905.1_UOB_LRV0_1_protein.faa"
RESULT_DIR="${OUTPUT_DIR}/interpro"
TEMP_DIR="${PROJECT_BASE}/tmp/interpro_${SLURM_JOB_ID}"

mkdir -p "${RESULT_DIR}" "${TEMP_DIR}"

cd "${INTERPRO_DIR}"

echo "[INFO] Running InterProScan for ${SPECIES}"

./interproscan.sh \
    -i "${INPUT_FAA}" \
    -t p \
    -goterms \
    -pa \
    -iprlookup \
    -b "${RESULT_DIR}/${SPECIES}" \
    --cpu "${SLURM_CPUS_PER_TASK}" \
    -T "${TEMP_DIR}"

rm -rf "${TEMP_DIR}"
echo "[DONE] InterProScan complete."
