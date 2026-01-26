#!/usr/bin/env python3
"""
Functional Annotation Pipeline - Annotation Results Analysis and Visualization

Description:
    This script analyzes and visualizes annotation results before integration.
    It provides statistics on gene coverage, annotation percentages per tool,
    and overlap analysis between different annotation tools.
    
    Key features:
    - Count total genes from protein FASTA file
    - Count annotated genes per tool (GO and KEGG terms)
    - Separate GO/KEGG counts for EggNOG
    - Pre- and post-filtering analysis for FANTASIA
    - Generate pie charts showing annotation percentages
    - Compare gene annotations across tools
    - Calculate overlaps between KofamScan, InterProScan, and EggNOG
    - Identify genes uniquely annotated by FANTASIA

Author: Aaron Kiggen
Repository: aaronkiggen/Functional_Annotation_Pipeline
"""

import argparse
import os
import sys
from pathlib import Path
from typing import Dict, Set, List, Tuple

try:
    import pandas as pd
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    from matplotlib.gridspec import GridSpec
except ImportError:
    print("Error: Required packages not found.")
    print("Please install: pip install pandas matplotlib openpyxl")
    sys.exit(1)


def parse_fasta_file(fasta_path: str) -> Set[str]:
    """
    Parse FASTA file and extract all gene/protein identifiers.
    
    Args:
        fasta_path: Path to protein FASTA file
        
    Returns:
        Set of gene/protein identifiers
    """
    genes = set()
    
    if not os.path.exists(fasta_path):
        print(f"Error: FASTA file not found: {fasta_path}")
        return genes
    
    with open(fasta_path, 'r') as f:
        for line in f:
            if line.startswith('>'):
                # Extract first word after '>' as gene/protein ID
                header = line[1:].strip()
                gene_id = header.split()[0]
                genes.add(gene_id)
    
    return genes


def read_per_gene_excel(excel_path: str) -> pd.DataFrame:
    """
    Read per-gene Excel file.
    
    Args:
        excel_path: Path to Excel file
        
    Returns:
        DataFrame with gene annotations
    """
    if not os.path.exists(excel_path):
        print(f"Warning: File not found: {excel_path}")
        return pd.DataFrame()
    
    try:
        df = pd.read_excel(excel_path, sheet_name='Annotations')
        return df
    except Exception as e:
        print(f"Error reading {excel_path}: {e}")
        return pd.DataFrame()


def count_annotated_genes_kofamscan(excel_path: str) -> Tuple[Set[str], int]:
    """
    Count genes with KEGG annotations from KofamScan per-gene output.
    
    Args:
        excel_path: Path to KofamScan per-gene Excel file
        
    Returns:
        Tuple of (set of annotated genes, count)
    """
    df = read_per_gene_excel(excel_path)
    if df.empty:
        return set(), 0
    
    # Genes with non-empty KEGG terms
    annotated = df[df['KEGG'].notna() & (df['KEGG'].astype(str).str.strip() != '')]
    annotated_genes = set(annotated['gene_name'].unique())
    
    return annotated_genes, len(annotated_genes)


def count_annotated_genes_interproscan(excel_path: str) -> Tuple[Set[str], int]:
    """
    Count genes with GO or Pathway annotations from InterProScan per-gene output.
    
    Args:
        excel_path: Path to InterProScan per-gene Excel file
        
    Returns:
        Tuple of (set of annotated genes, count)
    """
    df = read_per_gene_excel(excel_path)
    if df.empty:
        return set(), 0
    
    # Genes with GO terms or Pathways
    def has_annotation(row):
        has_go = pd.notna(row['GO']) and str(row['GO']).strip() != ''
        has_pathway = pd.notna(row['Pathways']) and str(row['Pathways']).strip() != ''
        return has_go or has_pathway
    
    annotated = df[df.apply(has_annotation, axis=1)]
    annotated_genes = set(annotated['gene'].unique())
    
    return annotated_genes, len(annotated_genes)


def count_annotated_genes_eggnog(excel_path: str) -> Dict[str, Tuple[Set[str], int]]:
    """
    Count genes with GO and KEGG annotations separately from EggNOG per-gene output.
    
    Args:
        excel_path: Path to EggNOG per-gene Excel file
        
    Returns:
        Dictionary with 'GO' and 'KEGG' keys, each containing (set of genes, count)
    """
    df = read_per_gene_excel(excel_path)
    if df.empty:
        return {'GO': (set(), 0), 'KEGG': (set(), 0)}
    
    # Determine gene column name (could be 'gene' or '#query')
    gene_col = 'gene' if 'gene' in df.columns else '#query' if '#query' in df.columns else None
    if gene_col is None:
        print(f"Warning: Could not find gene column in {excel_path}")
        return {'GO': (set(), 0), 'KEGG': (set(), 0)}
    
    # GO annotations
    go_annotated = df[df['GOs'].notna() & (df['GOs'].astype(str).str.strip() != '')]
    go_genes = set(go_annotated[gene_col].unique())
    
    # KEGG annotations (check KEGG_ko column)
    kegg_annotated = df[df['KEGG_ko'].notna() & (df['KEGG_ko'].astype(str).str.strip() != '')]
    kegg_genes = set(kegg_annotated[gene_col].unique())
    
    return {
        'GO': (go_genes, len(go_genes)),
        'KEGG': (kegg_genes, len(kegg_genes))
    }


def count_annotated_genes_fantasia(excel_path: str) -> Tuple[Set[str], int]:
    """
    Count genes with GO annotations from FANTASIA per-gene output.
    
    Args:
        excel_path: Path to FANTASIA per-gene Excel file
        
    Returns:
        Tuple of (set of annotated genes, count)
    """
    df = read_per_gene_excel(excel_path)
    if df.empty:
        return set(), 0
    
    # Genes with GO terms
    annotated = df[df['GO'].notna() & (df['GO'].astype(str).str.strip() != '')]
    annotated_genes = set(annotated['gene'].unique())
    
    return annotated_genes, len(annotated_genes)


def analyze_fantasia_models(excel_dir: str, sample_prefix: str) -> Dict:
    """
    Analyze FANTASIA results for all models (pre- and post-filtering).
    
    Args:
        excel_dir: Directory containing Excel files
        sample_prefix: Sample name prefix for file matching
        
    Returns:
        Dictionary with pre- and post-filtering statistics
    """
    models = ['ESM-2', 'ProtT5', 'ProstT5', 'Ankh3-Large', 'ESM3c']
    results = {
        'pre_filtering': {},
        'post_filtering': {}
    }
    
    for model in models:
        # Pre-filtering (unfiltered per-gene file)
        pre_file = os.path.join(excel_dir, f"{sample_prefix}_fantasia_{model}_per_gene.xlsx")
        if os.path.exists(pre_file):
            genes, count = count_annotated_genes_fantasia(pre_file)
            results['pre_filtering'][model] = (genes, count)
        else:
            results['pre_filtering'][model] = (set(), 0)
        
        # Post-filtering (filtered per-gene file)
        post_file = os.path.join(excel_dir, f"{sample_prefix}_fantasia_{model}_per_gene_filtered.xlsx")
        if os.path.exists(post_file):
            genes, count = count_annotated_genes_fantasia(post_file)
            results['post_filtering'][model] = (genes, count)
        else:
            # If filtered file doesn't exist, post-filtering same as pre-filtering
            results['post_filtering'][model] = results['pre_filtering'][model]
    
    return results


def create_annotation_summary(total_genes: int, annotations: Dict) -> pd.DataFrame:
    """
    Create summary DataFrame of annotation statistics.
    
    Args:
        total_genes: Total number of genes in FASTA
        annotations: Dictionary of annotation statistics
        
    Returns:
        DataFrame with summary statistics
    """
    summary_data = []
    
    for tool, data in annotations.items():
        if isinstance(data, tuple):
            genes, count = data
            percentage = (count / total_genes * 100) if total_genes > 0 else 0
            summary_data.append({
                'Tool': tool,
                'Annotated Genes': count,
                'Total Genes': total_genes,
                'Percentage': f"{percentage:.2f}%",
                'Percentage_Value': percentage
            })
        elif isinstance(data, dict):
            # Handle nested dictionaries (e.g., EggNOG with GO and KEGG)
            for subtype, (genes, count) in data.items():
                percentage = (count / total_genes * 100) if total_genes > 0 else 0
                summary_data.append({
                    'Tool': f"{tool} ({subtype})",
                    'Annotated Genes': count,
                    'Total Genes': total_genes,
                    'Percentage': f"{percentage:.2f}%",
                    'Percentage_Value': percentage
                })
    
    return pd.DataFrame(summary_data)


def plot_annotation_pie_charts(summary_df: pd.DataFrame, output_path: str):
    """
    Create pie charts showing annotation percentages for all tools.
    
    Args:
        summary_df: DataFrame with annotation summary
        output_path: Path to save the figure
    """
    # Prepare data for pie charts
    n_tools = len(summary_df)
    
    # Calculate grid dimensions
    n_cols = 3
    n_rows = (n_tools + n_cols - 1) // n_cols
    
    # Create figure with subplots
    fig = plt.figure(figsize=(15, 5 * n_rows))
    
    for idx, row in summary_df.iterrows():
        ax = plt.subplot(n_rows, n_cols, idx + 1)
        
        annotated = row['Annotated Genes']
        total = row['Total Genes']
        unannotated = total - annotated
        
        # Create pie chart
        sizes = [annotated, unannotated]
        labels = ['Annotated', 'Unannotated']
        colors = ['#4CAF50', '#E0E0E0']
        explode = (0.1, 0)
        
        ax.pie(sizes, explode=explode, labels=labels, colors=colors,
               autopct='%1.1f%%', shadow=True, startangle=90)
        ax.set_title(f"{row['Tool']}\n({annotated}/{total} genes)", fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved pie charts: {output_path}")
    plt.close()


def plot_combined_comparison(summary_df: pd.DataFrame, output_path: str):
    """
    Create combined bar chart comparing all tools.
    
    Args:
        summary_df: DataFrame with annotation summary
        output_path: Path to save the figure
    """
    fig, ax = plt.subplots(figsize=(12, 6))
    
    tools = summary_df['Tool']
    percentages = summary_df['Percentage_Value']
    
    # Create bar chart
    bars = ax.bar(range(len(tools)), percentages, color='#2196F3', edgecolor='black')
    
    # Customize plot
    ax.set_xlabel('Tool', fontweight='bold', fontsize=12)
    ax.set_ylabel('Percentage of Genes Annotated (%)', fontweight='bold', fontsize=12)
    ax.set_title('Gene Annotation Coverage by Tool', fontweight='bold', fontsize=14)
    ax.set_xticks(range(len(tools)))
    ax.set_xticklabels(tools, rotation=45, ha='right')
    ax.set_ylim(0, 100)
    ax.grid(axis='y', alpha=0.3)
    
    # Add percentage labels on bars
    for bar, pct in zip(bars, percentages):
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2., height,
                f'{pct:.1f}%',
                ha='center', va='bottom', fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"✓ Saved comparison chart: {output_path}")
    plt.close()


def calculate_overlaps(gene_sets: Dict[str, Set[str]]) -> Dict:
    """
    Calculate overlaps between different annotation tools.
    
    Args:
        gene_sets: Dictionary mapping tool names to sets of annotated genes
        
    Returns:
        Dictionary with overlap statistics
    """
    overlaps = {}
    
    # All tools combined
    all_tools = set.union(*gene_sets.values()) if gene_sets else set()
    overlaps['all_tools_combined'] = (all_tools, len(all_tools))
    
    # Genes annotated by all tools
    if len(gene_sets) > 0:
        genes_all_tools = set.intersection(*gene_sets.values())
        overlaps['annotated_by_all'] = (genes_all_tools, len(genes_all_tools))
    else:
        overlaps['annotated_by_all'] = (set(), 0)
    
    # KofamScan, InterProScan, and EggNOG combined
    kofam_interpro_eggnog = set()
    if 'KofamScan' in gene_sets:
        kofam_interpro_eggnog.update(gene_sets['KofamScan'])
    if 'InterProScan' in gene_sets:
        kofam_interpro_eggnog.update(gene_sets['InterProScan'])
    if 'EggNOG (combined)' in gene_sets:
        kofam_interpro_eggnog.update(gene_sets['EggNOG (combined)'])
    
    overlaps['kofam_interpro_eggnog_combined'] = (kofam_interpro_eggnog, len(kofam_interpro_eggnog))
    
    # Overlap between KofamScan, InterProScan, and EggNOG (genes in all three)
    if 'KofamScan' in gene_sets and 'InterProScan' in gene_sets and 'EggNOG (combined)' in gene_sets:
        overlap_3tools = gene_sets['KofamScan'] & gene_sets['InterProScan'] & gene_sets['EggNOG (combined)']
        overlaps['kofam_interpro_eggnog_overlap'] = (overlap_3tools, len(overlap_3tools))
    else:
        overlaps['kofam_interpro_eggnog_overlap'] = (set(), 0)
    
    # FANTASIA unique annotations (genes only in FANTASIA, not in the three main tools)
    if 'FANTASIA (post-filtering)' in gene_sets:
        fantasia_unique = gene_sets['FANTASIA (post-filtering)'] - kofam_interpro_eggnog
        overlaps['fantasia_unique'] = (fantasia_unique, len(fantasia_unique))
    else:
        overlaps['fantasia_unique'] = (set(), 0)
    
    return overlaps


def create_venn_style_summary(overlaps: Dict, output_path: str):
    """
    Create a text-based summary of overlaps (Venn diagram style).
    
    Args:
        overlaps: Dictionary with overlap statistics
        output_path: Path to save the summary text file
    """
    with open(output_path, 'w') as f:
        f.write("="*60 + "\n")
        f.write("Gene Annotation Overlap Analysis\n")
        f.write("="*60 + "\n\n")
        
        f.write(f"All tools combined: {overlaps['all_tools_combined'][1]} genes\n")
        f.write(f"Genes annotated by ALL tools: {overlaps['annotated_by_all'][1]} genes\n\n")
        
        f.write("-"*60 + "\n")
        f.write("KofamScan + InterProScan + EggNOG Analysis:\n")
        f.write("-"*60 + "\n")
        f.write(f"Combined (union): {overlaps['kofam_interpro_eggnog_combined'][1]} genes\n")
        f.write(f"Overlap (intersection): {overlaps['kofam_interpro_eggnog_overlap'][1]} genes\n\n")
        
        f.write("-"*60 + "\n")
        f.write("FANTASIA Unique Contributions:\n")
        f.write("-"*60 + "\n")
        f.write(f"Genes uniquely annotated by FANTASIA: {overlaps['fantasia_unique'][1]} genes\n")
        f.write("(These genes were not annotated by KofamScan, InterProScan, or EggNOG)\n\n")
        
        if overlaps['fantasia_unique'][1] > 0:
            f.write("\nExample FANTASIA-unique gene IDs (first 10):\n")
            for gene in list(overlaps['fantasia_unique'][0])[:10]:
                f.write(f"  - {gene}\n")
    
    print(f"✓ Saved overlap summary: {output_path}")


def main():
    """Main function to parse arguments and run analysis"""
    parser = argparse.ArgumentParser(
        description='Analyze and visualize annotation results before integration',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic usage
  python analyze_annotation_results.py --fasta proteins.faa --excel-dir excel_outputs/ --sample mysample
  
  # With custom output directory
  python analyze_annotation_results.py --fasta proteins.faa --excel-dir excel_outputs/ --sample mysample --output-dir analysis/
        """
    )
    
    parser.add_argument(
        '--fasta',
        required=True,
        help='Path to protein FASTA file'
    )
    
    parser.add_argument(
        '--excel-dir',
        required=True,
        help='Directory containing Excel files generated by create_excel_outputs.py'
    )
    
    parser.add_argument(
        '--sample',
        required=True,
        help='Sample name prefix for file matching (e.g., "mysample" for mysample_kofamscan_per_gene.xlsx)'
    )
    
    parser.add_argument(
        '--output-dir',
        default='.',
        help='Directory to save analysis outputs (default: current directory)'
    )
    
    args = parser.parse_args()
    
    # Validate inputs
    if not os.path.exists(args.fasta):
        print(f"Error: FASTA file not found: {args.fasta}")
        sys.exit(1)
    
    if not os.path.exists(args.excel_dir):
        print(f"Error: Excel directory not found: {args.excel_dir}")
        sys.exit(1)
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    print("="*60)
    print("Annotation Results Analysis")
    print("="*60)
    print(f"FASTA file: {args.fasta}")
    print(f"Excel directory: {args.excel_dir}")
    print(f"Sample prefix: {args.sample}")
    print(f"Output directory: {args.output_dir}")
    
    # Step 1: Count total genes
    print("\n" + "="*60)
    print("Step 1: Counting Total Genes from FASTA")
    print("="*60)
    total_genes_set = parse_fasta_file(args.fasta)
    total_genes = len(total_genes_set)
    print(f"Total genes in FASTA: {total_genes}")
    
    # Step 2: Count annotated genes per tool
    print("\n" + "="*60)
    print("Step 2: Counting Annotated Genes per Tool")
    print("="*60)
    
    annotations = {}
    gene_sets = {}
    
    # KofamScan
    kofam_file = os.path.join(args.excel_dir, f"{args.sample}_kofamscan_per_gene.xlsx")
    if os.path.exists(kofam_file):
        genes, count = count_annotated_genes_kofamscan(kofam_file)
        annotations['KofamScan'] = (genes, count)
        gene_sets['KofamScan'] = genes
        print(f"✓ KofamScan: {count} genes with KEGG annotations")
    else:
        print(f"⚠ KofamScan file not found: {kofam_file}")
    
    # InterProScan
    interpro_file = os.path.join(args.excel_dir, f"{args.sample}_interproscan_per_gene.xlsx")
    if os.path.exists(interpro_file):
        genes, count = count_annotated_genes_interproscan(interpro_file)
        annotations['InterProScan'] = (genes, count)
        gene_sets['InterProScan'] = genes
        print(f"✓ InterProScan: {count} genes with GO/Pathway annotations")
    else:
        print(f"⚠ InterProScan file not found: {interpro_file}")
    
    # EggNOG (check for v5 or v7)
    eggnog_file = None
    for version in ['v5', 'v7']:
        test_file = os.path.join(args.excel_dir, f"{args.sample}_eggnog_{version}_per_gene.xlsx")
        if os.path.exists(test_file):
            eggnog_file = test_file
            break
    
    if eggnog_file:
        eggnog_data = count_annotated_genes_eggnog(eggnog_file)
        annotations['EggNOG'] = eggnog_data
        print(f"✓ EggNOG (GO): {eggnog_data['GO'][1]} genes with GO annotations")
        print(f"✓ EggNOG (KEGG): {eggnog_data['KEGG'][1]} genes with KEGG annotations")
        # Combined EggNOG genes (with either GO or KEGG)
        eggnog_combined = eggnog_data['GO'][0] | eggnog_data['KEGG'][0]
        gene_sets['EggNOG (combined)'] = eggnog_combined
    else:
        print(f"⚠ EggNOG file not found")
    
    # FANTASIA - analyze all models
    print("\n" + "-"*60)
    print("FANTASIA Analysis (Pre- and Post-Filtering)")
    print("-"*60)
    fantasia_results = analyze_fantasia_models(args.excel_dir, args.sample)
    
    # Pre-filtering
    print("\nPre-filtering:")
    for model, (genes, count) in fantasia_results['pre_filtering'].items():
        annotations[f'FANTASIA {model} (pre)'] = (genes, count)
        print(f"  {model}: {count} genes")
    
    # Post-filtering
    print("\nPost-filtering:")
    fantasia_post_combined = set()
    for model, (genes, count) in fantasia_results['post_filtering'].items():
        annotations[f'FANTASIA {model} (post)'] = (genes, count)
        fantasia_post_combined.update(genes)
        print(f"  {model}: {count} genes")
    
    # Use consensus or combined post-filtering for overlap analysis
    gene_sets['FANTASIA (post-filtering)'] = fantasia_post_combined
    
    # Step 3: Create summary statistics
    print("\n" + "="*60)
    print("Step 3: Creating Summary Statistics")
    print("="*60)
    summary_df = create_annotation_summary(total_genes, annotations)
    
    # Save summary to CSV
    summary_csv = os.path.join(args.output_dir, f"{args.sample}_annotation_summary.csv")
    summary_df.to_csv(summary_csv, index=False)
    print(f"✓ Saved summary: {summary_csv}")
    
    # Display summary
    print("\nAnnotation Summary:")
    print(summary_df.to_string(index=False))
    
    # Step 4: Create visualizations
    print("\n" + "="*60)
    print("Step 4: Creating Visualizations")
    print("="*60)
    
    # Pie charts
    pie_chart_path = os.path.join(args.output_dir, f"{args.sample}_annotation_pie_charts.png")
    plot_annotation_pie_charts(summary_df, pie_chart_path)
    
    # Comparison bar chart
    comparison_path = os.path.join(args.output_dir, f"{args.sample}_annotation_comparison.png")
    plot_combined_comparison(summary_df, comparison_path)
    
    # Step 5: Calculate overlaps
    print("\n" + "="*60)
    print("Step 5: Calculating Tool Overlaps")
    print("="*60)
    overlaps = calculate_overlaps(gene_sets)
    
    print(f"All tools combined: {overlaps['all_tools_combined'][1]} genes")
    print(f"Genes annotated by ALL tools: {overlaps['annotated_by_all'][1]} genes")
    print(f"\nKofamScan + InterProScan + EggNOG:")
    print(f"  Combined: {overlaps['kofam_interpro_eggnog_combined'][1]} genes")
    print(f"  Overlap: {overlaps['kofam_interpro_eggnog_overlap'][1]} genes")
    print(f"\nFANTASIA unique annotations: {overlaps['fantasia_unique'][1]} genes")
    
    # Save overlap summary
    overlap_summary_path = os.path.join(args.output_dir, f"{args.sample}_overlap_summary.txt")
    create_venn_style_summary(overlaps, overlap_summary_path)
    
    print("\n" + "="*60)
    print("Analysis Complete!")
    print("="*60)
    print(f"\nOutput files saved to: {args.output_dir}")
    print(f"  - {args.sample}_annotation_summary.csv")
    print(f"  - {args.sample}_annotation_pie_charts.png")
    print(f"  - {args.sample}_annotation_comparison.png")
    print(f"  - {args.sample}_overlap_summary.txt")


if __name__ == '__main__':
    main()
