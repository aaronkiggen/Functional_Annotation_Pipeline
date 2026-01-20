#!/bin/bash -l
#SBATCH --job-name=01_isoform
#SBATCH --cluster=genius
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=02:00:00
#SBATCH -A lp_svbelleghem
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Load config
source ../config.env

SPECIES="LRV01"
TARGET_DIR="${INPUT_DIR}/${SPECIES}"
FAA_FILE="${TARGET_DIR}/GCA_030254905.1_UOB_LRV0_1_protein.faa"
HELPER_SCRIPT="$(pwd)/helper/primary_transcript.py"

echo "[INFO] Starting longest ORF selection for ${SPECIES}"

if [[ ! -f "${FAA_FILE}" ]]; then
    echo "ERROR: Input file ${FAA_FILE} not found" >&2
    exit 1
fi

mkdir -p "${TARGET_DIR}/primary_transcripts"

# Run extraction
python "${HELPER_SCRIPT}" "${FAA_FILE}"

echo "[DONE] Primary transcripts extracted."
