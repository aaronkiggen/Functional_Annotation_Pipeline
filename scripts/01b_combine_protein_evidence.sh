#!/bin/bash
# ==============================================================================
# Script: 01b_combine_protein_evidence.sh
# Description: Concatenates user-provided sister species proteomes with the 
#              default OrthoDB partition for improved BRAKER4 accuracy.
# ==============================================================================

set -e

# Load paths from config
source "$(dirname "$0")/../config.env"

BRAKER_OUT_DIR="${RESULTS_DIR}/braker4"
CUSTOM_PROT_DIR="${PIPELINE_SCRATCH}/custom_proteins"
ORTHODB_FA="${BRAKER_OUT_DIR}/Arthropoda.fa"
COMBINED_FA="${BRAKER_OUT_DIR}/custom_evidence.fa"

# Ensure directories exist
mkdir -p "${CUSTOM_PROT_DIR}"
mkdir -p "${BRAKER_OUT_DIR}"

echo "============================================================"
echo "    Preparing Custom Protein Evidence for BRAKER4           "
echo "============================================================"

# 1. Download OrthoDB if it doesn't exist yet
if [ ! -f "${ORTHODB_FA}" ]; then
    echo "Downloading baseline OrthoDB Arthropoda partition..."
    wget -qO "${ORTHODB_FA}.gz" https://bioinf.uni-greifswald.de/bioinf/partitioned_odb12/Arthropoda.fa.gz
    gunzip "${ORTHODB_FA}.gz"
else
    echo "Baseline OrthoDB partition found at ${ORTHODB_FA}"
fi

# 2. Start the combined file with OrthoDB
echo "Initializing ${COMBINED_FA}..."
cp "${ORTHODB_FA}" "${COMBINED_FA}"

# 3. Concatenate user-provided fastas
count=0
# Enable nullglob so loop doesn't fail if no files match
shopt -s nullglob
for file in "${CUSTOM_PROT_DIR}"/*.{fa,faa,fasta}; do
    if [ -f "$file" ]; then
        echo " ➔ Appending custom proteome: $(basename "$file")"
        
        # Add a newline just in case the previous file didn't end with one,
        # then append the new protein file
        echo "" >> "${COMBINED_FA}" 
        cat "$file" >> "${COMBINED_FA}"
        
        count=$((count + 1))
    fi
done
shopt -u nullglob

echo "------------------------------------------------------------"
if [ $count -eq 0 ]; then
    echo "⚠ No custom protein files found in:"
    echo "  ${CUSTOM_PROT_DIR}"
    echo "  (Only the default OrthoDB database was used.)"
    echo "  Drop your .faa files into that folder and re-run if needed."
else
    echo "✓ Successfully concatenated ${count} custom protein files!"
fi
echo "============================================================"
echo "Output saved to: ${COMBINED_FA}"
echo "NOTE: Update your 'samples.csv' inside '01_prep_braker4.sh'"
echo "      to point to '${COMBINED_FA}' instead of 'Arthropoda.fa'."
echo "============================================================"
