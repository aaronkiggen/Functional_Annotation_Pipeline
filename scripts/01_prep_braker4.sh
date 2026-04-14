#!/bin/bash
# ==============================================================================
# Script: 01_prep_braker4.sh
# Description: Prepares the input CSV and config.ini for BRAKER4 runs
# ==============================================================================

set -e

# Directories
source "$(dirname "$0")/../config.env"
GENOME_DIR="${INPUT_DIR}"   # Assuming genomes are here based on workspace struct
OUT_DIR="${RESULTS_DIR}/braker4"
mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

# Download OrthoDB partition for Arthropoda (assuming Daphnia/Arthropods based on names like pulex)
if [ ! -f "Arthropoda.fa" ]; then
    echo "Downloading OrthoDB Arthropoda partition..."
    wget https://bioinf.uni-greifswald.de/bioinf/partitioned_odb12/Arthropoda.fa.gz
    gunzip Arthropoda.fa.gz
fi

# ==============================================================================
# 1. Create samples.csv
# ==============================================================================
SAMPLES_CSV="samples.csv"
echo "sample_name,genome,genome_masked,protein_fasta,bam_files,fastq_r1,fastq_r2,sra_ids,varus_genus,varus_species,isoseq_bam,isoseq_fastq,busco_lineage,reference_gtf" > "${SAMPLES_CSV}"

# We will create two rows per species: 
# 1) protein-only (EP mode)
# 2) VARSUS RNA-seq (ETP mode)

# Example: adding Daphnia pulex
echo "pulex_prot,${GENOME_DIR}/Daphnia_pulex.fa,,${OUT_DIR}/Arthropoda.fa,,,,,,,,,arthropoda_odb12," >> "${SAMPLES_CSV}"
echo "pulex_varsus,${GENOME_DIR}/Daphnia_pulex.fa,,${OUT_DIR}/Arthropoda.fa,,,,,Daphnia,pulex,,,,arthropoda_odb12," >> "${SAMPLES_CSV}"

# Example: adding Daphnia magna
echo "magna_prot,${GENOME_DIR}/Daphnia_magna.fa,,${OUT_DIR}/Arthropoda.fa,,,,,,,,,arthropoda_odb12," >> "${SAMPLES_CSV}"
echo "magna_varsus,${GENOME_DIR}/Daphnia_magna.fa,,${OUT_DIR}/Arthropoda.fa,,,,,Daphnia,magna,,,,arthropoda_odb12," >> "${SAMPLES_CSV}"

echo "Generated ${SAMPLES_CSV}"

# ==============================================================================
# 2. Create config.ini
# ==============================================================================
CONFIG_INI="config.ini"
cat << 'EOF' > "${CONFIG_INI}"
[paths]
samples_file = samples.csv
augustus_config_path = augustus_config

[PARAMS]
fungus = 0
use_varus = 1
skip_optimize_augustus = 0
use_compleasm_hints = 1
skip_compleasm = 0
skip_busco = 0
run_omark = 0
run_ncrna = 0
run_best_by_compleasm = 1
masking_tool = repeatmasker

[fantasia]
# Enable FANTASIA-Lite for functional annotation inside BRAKER4
enable = 1
# Adjust SLURM parameters for FANTASIA
partition = gpu
gpus = 1
mem_mb = 25000
cpus_per_task = 16
max_runtime = 1440
min_score = 0.5

[SLURM_ARGS]
cpus_per_task = 16
mem_of_node = 64000
max_runtime = 2880
EOF

echo "Generated ${CONFIG_INI}"
echo "Preparation complete. You can now run the SLURM script."
