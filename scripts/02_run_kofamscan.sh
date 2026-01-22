#!/bin/bash -l
#SBATCH --job-name=kofam
#SBATCH --cluster=genius
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=06:00:00
#SBATCH -A lp_svbelleghem
#SBATCH --output=kofam_LRV01.%j.out
#SBATCH --error=kofam_LRV01.%j.err

echo "[INFO] Job started on $(date)"

# ------------------
# Activate conda
# ------------------
source /vsc-hard-mounts/leuven-data/354/vsc35429/miniconda3/etc/profile.d/conda.sh
conda activate kofam

# ------------------
# Paths
# ------------------

BASE=/lustre1/scratch/354/vsc35429
KOFAM=${BASE}/KOSCAN/kofam_scan
DB=${BASE}/KOSCAN
INPUT=${BASE}/Daphnia_magna_annotation/input/LRV01/primary_transcripts
OUT=${BASE}/Daphnia_magna_annotation/outputs/results/kofam  # <-- fixed

# Make sure output exists
mkdir -p "${OUT}"

# ------------------
# Run KofamScan
# ------------------
exec_annotation -p ${DB}/profiles/eukaryote.hal \
                -k ${DB}/ko_list \
                -f mapper \
                -o ${OUT}/LRV01_kofam_mapper.tsv \
                ${INPUT}/GCA_030254905.1_UOB_LRV0_1_protein.faa \
                --cpu=16 \
                --tmp-dir ${BASE}/KOSCAN/tmp

echo "[INFO] Job finished on $(date)"
