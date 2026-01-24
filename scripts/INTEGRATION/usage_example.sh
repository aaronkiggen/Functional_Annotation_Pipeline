#!/bin/bash
#
# Example usage script for create_excel_outputs.py
#
# This script demonstrates how to generate Excel outputs from 
# functional annotation results

set -e

echo "================================================"
echo "Functional Annotation Excel Output Generator"
echo "================================================"
echo

# Check if results directory exists
RESULTS_DIR="../../results"
if [ ! -d "${RESULTS_DIR}" ]; then
    echo "Warning: Results directory not found: ${RESULTS_DIR}"
    echo "Please make sure you've run the annotation steps (02-04) first."
    exit 1
fi

# Create output directory
OUTPUT_DIR="./excel_outputs"
mkdir -p "${OUTPUT_DIR}"

echo "Processing annotation results..."
echo "  Results directory: ${RESULTS_DIR}"
echo "  Output directory:  ${OUTPUT_DIR}"
echo

# Run the script
python3 create_excel_outputs.py \
    --results-dir "${RESULTS_DIR}" \
    --output-dir "${OUTPUT_DIR}"

echo
echo "================================================"
echo "Complete! Check ${OUTPUT_DIR} for Excel files."
echo "================================================"
