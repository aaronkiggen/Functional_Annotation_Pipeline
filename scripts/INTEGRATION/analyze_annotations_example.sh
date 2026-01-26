#!/bin/bash
#
# Example usage script for analyze_annotation_results.py
#
# This script demonstrates how to analyze and visualize annotation results

set -e

echo "================================================"
echo "Annotation Results Analysis and Visualization"
echo "================================================"
echo

# Configuration
FASTA_FILE="../../proteins/sample.faa"  # Adjust this path
EXCEL_DIR="./excel_outputs"
SAMPLE_NAME="sample"  # Adjust this to your sample name
OUTPUT_DIR="./analysis_results"

# Check if FASTA file exists
if [ ! -f "${FASTA_FILE}" ]; then
    echo "Error: FASTA file not found: ${FASTA_FILE}"
    echo "Please adjust the FASTA_FILE path in this script."
    exit 1
fi

# Check if Excel directory exists
if [ ! -d "${EXCEL_DIR}" ]; then
    echo "Error: Excel directory not found: ${EXCEL_DIR}"
    echo "Please run create_excel_outputs.py first."
    exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

echo "Analyzing annotation results..."
echo "  FASTA file:    ${FASTA_FILE}"
echo "  Excel dir:     ${EXCEL_DIR}"
echo "  Sample name:   ${SAMPLE_NAME}"
echo "  Output dir:    ${OUTPUT_DIR}"
echo

# Run the analysis script
python3 analyze_annotation_results.py \
    --fasta "${FASTA_FILE}" \
    --excel-dir "${EXCEL_DIR}" \
    --sample "${SAMPLE_NAME}" \
    --output-dir "${OUTPUT_DIR}"

echo
echo "================================================"
echo "Complete! Check ${OUTPUT_DIR} for results:"
echo "  - ${SAMPLE_NAME}_annotation_summary.csv"
echo "  - ${SAMPLE_NAME}_annotation_pie_charts.png"
echo "  - ${SAMPLE_NAME}_annotation_comparison.png"
echo "  - ${SAMPLE_NAME}_overlap_summary.txt"
echo "================================================"
