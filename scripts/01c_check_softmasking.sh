#!/bin/bash
# ==============================================================================
# Script: 01c_check_softmasking.sh
# Description: Rapidly scans input genome FASTA files to determine if they 
#              are already soft-masked (containing lowercase a, c, g, t).
# ==============================================================================

source "$(dirname "$0")/../config.env"

echo "============================================================"
echo "    Checking Genomes for Soft-Masking"
echo "    Directory: ${INPUT_DIR}"
echo "============================================================"

count=0
shopt -s nullglob
for file in "${INPUT_DIR}"/*.{fa,fasta,fna}; do
    if [ -f "$file" ]; then
        count=$((count + 1))
        filename=$(basename "$file")
        
        # We sample the first 50,000 lines to make it instant. 
        # If a genome is soft-masked, repeats will definitely appear in the first 50k lines.
        if head -n 50000 "$file" | grep -v "^>" | grep -q -E "[acgt]"; then
            echo -e " ➔ ${filename}: \033[1;32mSOFT-MASKED\033[0m (Lowercase bases detected)"
        else
            # Check if it has Ns (Hard-masked or just sequence gaps)
            if head -n 50000 "$file" | grep -v "^>" | grep -q "N"; then
                echo -e " ➔ ${filename}: \033[1;33mUNMASKED / HARD-MASKED\033[0m (No lowercase found, but contains Ns)"
            else
                echo -e " ➔ ${filename}: \033[1;31mUNMASKED\033[0m (All uppercase, no lowercase bases)"
            fi
        fi
    fi
done
shopt -u nullglob

if [ $count -eq 0 ]; then
    echo "⚠ No genome fasta files (.fa, .fasta, .fna) found in ${INPUT_DIR}"
    echo "Drop your genomes there first!"
fi

echo "============================================================"
echo "NOTE: If your genomes are SOFT-MASKED, you should remove or comment out"
echo "      'masking_tool = repeatmasker' in scripts/01_prep_braker4.sh"
echo "      to save considerable compute time."
echo "============================================================"
