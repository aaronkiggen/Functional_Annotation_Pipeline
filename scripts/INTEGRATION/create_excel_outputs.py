#!/usr/bin/env python3
"""
Functional Annotation Pipeline - Excel Output Generator

Description:
    This script parses output files from functional annotation tools
    (KofamScan, InterProScan, and EggNOG-mapper) and generates Excel
    files with standardized format: gene_name | functional_term | extra_information

Author: Aaron Kiggen
Repository: aaronkiggen/Functional_Annotation_Pipeline
"""

import argparse
import gzip
import os
import sys
from pathlib import Path
from typing import List, Dict, Tuple

try:
    import pandas as pd
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill, Alignment
except ImportError:
    print("Error: Required packages not found.")
    print("Please install: pip install pandas openpyxl")
    sys.exit(1)


class AnnotationParser:
    """Base class for parsing annotation files"""
    
    # Constants
    KEGG_PREFIX = 'ko:'
    KEGG_PREFIX_LEN = len(KEGG_PREFIX)
    
    def __init__(self, input_file: str):
        self.input_file = input_file
        self.results = []
    
    def parse(self):
        """Parse the input file - to be implemented by subclasses"""
        raise NotImplementedError
    
    def to_dataframe(self) -> pd.DataFrame:
        """Convert results to pandas DataFrame"""
        if not self.results:
            return pd.DataFrame(columns=['gene_name', 'functional_term', 'extra_information'])
        return pd.DataFrame(self.results)
    
    def save_to_excel(self, output_file: str):
        """Save results to Excel file with formatting"""
        df = self.to_dataframe()
        
        if df.empty:
            print(f"Warning: No data to write for {output_file}")
            return
        
        # Create Excel writer
        with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
            df.to_excel(writer, index=False, sheet_name='Annotations')
            
            # Get workbook and worksheet
            workbook = writer.book
            worksheet = writer.sheets['Annotations']
            
            # Format header
            header_fill = PatternFill(start_color="366092", end_color="366092", fill_type="solid")
            header_font = Font(bold=True, color="FFFFFF")
            
            for cell in worksheet[1]:
                cell.fill = header_fill
                cell.font = header_font
                cell.alignment = Alignment(horizontal='center')
            
            # Adjust column widths
            worksheet.column_dimensions['A'].width = 25  # gene_name
            worksheet.column_dimensions['B'].width = 20  # functional_term
            worksheet.column_dimensions['C'].width = 60  # extra_information
        
        print(f"✓ Created: {output_file} ({len(df)} rows)")


class KofamScanParser(AnnotationParser):
    """Parser for KofamScan output files"""
    
    def parse(self):
        """
        Parse KofamScan mapper output format:
        # gene_name    KO      threshold    score    E-value
        """
        self.results = []
        
        if not os.path.exists(self.input_file):
            print(f"Warning: File not found: {self.input_file}")
            return
        
        with open(self.input_file, 'r') as f:
            for line in f:
                # Skip comments and empty lines
                if line.startswith('#') or not line.strip():
                    continue
                
                parts = line.strip().split('\t')
                if len(parts) >= 5:
                    gene_name = parts[0]
                    ko_id = parts[1]
                    threshold = parts[2]
                    score = parts[3]
                    evalue = parts[4]
                    
                    # KO is the functional term (KEGG)
                    functional_term = ko_id
                    
                    # Extra information includes score and E-value
                    extra_info = f"Score: {score}, E-value: {evalue}, Threshold: {threshold}"
                    
                    self.results.append({
                        'gene_name': gene_name,
                        'functional_term': functional_term,
                        'extra_information': extra_info
                    })


class InterProScanParser(AnnotationParser):
    """Parser for InterProScan TSV output files"""
    
    def parse(self):
        """
        Parse InterProScan TSV format:
        Columns: 0=Protein_ID, 4=Signature_accession, 5=Signature_description,
                11=InterPro_ID, 12=InterPro_description, 13=GO_terms
        """
        self.results = []
        
        if not os.path.exists(self.input_file):
            print(f"Warning: File not found: {self.input_file}")
            return
        
        with open(self.input_file, 'r') as f:
            for line in f:
                # Skip comments
                if line.startswith('#'):
                    continue
                
                parts = line.strip().split('\t')
                if len(parts) < 6:
                    continue
                
                gene_name = parts[0]
                signature_acc = parts[4] if len(parts) > 4 else ""
                signature_desc = parts[5] if len(parts) > 5 else ""
                interpro_id = parts[11] if len(parts) > 11 else ""
                interpro_desc = parts[12] if len(parts) > 12 else ""
                go_terms = parts[13] if len(parts) > 13 else ""
                
                # If GO terms are present, create entries for each GO term
                if go_terms:
                    go_list = go_terms.split('|')
                    for go_term in go_list:
                        if go_term.strip():
                            # GO term is the functional term
                            functional_term = go_term.strip()
                            
                            # Extra information includes signature and InterPro details
                            extra_parts = []
                            if signature_desc:
                                extra_parts.append(f"Domain: {signature_desc} ({signature_acc})")
                            if interpro_desc and interpro_id:
                                extra_parts.append(f"InterPro: {interpro_desc} ({interpro_id})")
                            
                            extra_info = "; ".join(extra_parts) if extra_parts else signature_desc
                            
                            self.results.append({
                                'gene_name': gene_name,
                                'functional_term': functional_term,
                                'extra_information': extra_info
                            })
                else:
                    # No GO terms, but we can still record domain information
                    if signature_acc:
                        functional_term = signature_acc
                        extra_info = signature_desc if signature_desc else ""
                        if interpro_id:
                            extra_info += f" | InterPro: {interpro_desc} ({interpro_id})" if interpro_desc else f" | InterPro: {interpro_id}"
                        
                        self.results.append({
                            'gene_name': gene_name,
                            'functional_term': functional_term,
                            'extra_information': extra_info
                        })


class EggNOGParser(AnnotationParser):
    """Parser for EggNOG-mapper annotation files"""
    
    def parse(self):
        """
        Parse EggNOG .emapper.annotations format:
        Columns include: query, seed_ortholog, evalue, score, eggNOG_OGs,
                        GO_terms, KEGG_ko, Description
        """
        self.results = []
        
        if not os.path.exists(self.input_file):
            print(f"Warning: File not found: {self.input_file}")
            return
        
        # Determine if file is gzipped
        is_gzipped = self.input_file.endswith('.gz')
        
        open_func = gzip.open if is_gzipped else open
        mode = 'rt' if is_gzipped else 'r'
        
        with open_func(self.input_file, mode) as f:
            header_line = None
            for line in f:
                # Find header line
                if line.startswith('#query'):
                    header_line = line.strip().lstrip('#').split('\t')
                    continue
                
                # Skip other comments
                if line.startswith('#'):
                    continue
                
                parts = line.strip().split('\t')
                
                if not header_line or len(parts) < len(header_line):
                    continue
                
                # Create dictionary from header and values
                row_dict = dict(zip(header_line, parts))
                
                gene_name = row_dict.get('query', '')
                go_terms = row_dict.get('GOs', '') or row_dict.get('GO_terms', '')
                kegg_ko = row_dict.get('KEGG_ko', '') or row_dict.get('KEGG_KO', '')
                description = row_dict.get('Description', '') or row_dict.get('eggNOG_desc', '')
                seed_ortholog = row_dict.get('seed_ortholog', '')
                evalue = row_dict.get('evalue', '')
                score = row_dict.get('score', '')
                
                # Process GO terms
                if go_terms and go_terms != '-':
                    go_list = go_terms.split(',')
                    for go_term in go_list:
                        go_term = go_term.strip()
                        if go_term:
                            extra_parts = []
                            if description and description != '-':
                                extra_parts.append(f"Description: {description}")
                            if seed_ortholog and seed_ortholog != '-':
                                extra_parts.append(f"Best hit: {seed_ortholog}")
                            if evalue and evalue != '-':
                                extra_parts.append(f"E-value: {evalue}")
                            
                            extra_info = "; ".join(extra_parts)
                            
                            self.results.append({
                                'gene_name': gene_name,
                                'functional_term': go_term,
                                'extra_information': extra_info
                            })
                
                # Process KEGG KO terms
                if kegg_ko and kegg_ko != '-':
                    ko_list = kegg_ko.split(',')
                    for ko in ko_list:
                        ko = ko.strip()
                        # Remove 'ko:' prefix if present
                        if ko.startswith(self.KEGG_PREFIX):
                            ko = ko[self.KEGG_PREFIX_LEN:]
                        if ko:
                            extra_parts = []
                            if description and description != '-':
                                extra_parts.append(f"Description: {description}")
                            if seed_ortholog and seed_ortholog != '-':
                                extra_parts.append(f"Best hit: {seed_ortholog}")
                            if score and score != '-':
                                extra_parts.append(f"Score: {score}")
                            
                            extra_info = "; ".join(extra_parts)
                            
                            self.results.append({
                                'gene_name': gene_name,
                                'functional_term': ko,
                                'extra_information': extra_info
                            })


class EggNOG7Parser(AnnotationParser):
    """Parser for EggNOG 7 annotator output files"""
    
    def parse(self):
        """
        Parse EggNOG 7 .eggnog.tsv.gz format:
        Tab-separated with columns for gene, GO terms, KEGG terms, etc.
        """
        self.results = []
        
        if not os.path.exists(self.input_file):
            print(f"Warning: File not found: {self.input_file}")
            return
        
        # File should be gzipped
        with gzip.open(self.input_file, 'rt') as f:
            header_line = None
            for line in f:
                # Find header line
                if line.startswith('#query'):
                    header_line = line.strip().lstrip('#').split('\t')
                    continue
                
                # Skip other comments
                if line.startswith('#'):
                    continue
                
                parts = line.strip().split('\t')
                
                if not header_line or len(parts) < len(header_line):
                    continue
                
                # Create dictionary from header and values
                row_dict = dict(zip(header_line, parts))
                
                gene_name = row_dict.get('query', '')
                go_terms = row_dict.get('GOs', '') or row_dict.get('GO', '')
                kegg_ko = row_dict.get('KEGG_KO', '') or row_dict.get('KEGG_ko', '')
                description = row_dict.get('description', '') or row_dict.get('Description', '')
                protein_name = row_dict.get('protein_name', '') or row_dict.get('eggNOG_protein', '')
                evalue = row_dict.get('evalue', '')
                
                # Process GO terms
                if go_terms and go_terms != '-':
                    go_list = go_terms.split(',')
                    for go_term in go_list:
                        go_term = go_term.strip()
                        if go_term:
                            extra_parts = []
                            if protein_name and protein_name != '-':
                                extra_parts.append(f"Protein: {protein_name}")
                            if description and description != '-':
                                extra_parts.append(f"Description: {description}")
                            if evalue and evalue != '-':
                                extra_parts.append(f"E-value: {evalue}")
                            
                            extra_info = "; ".join(extra_parts)
                            
                            self.results.append({
                                'gene_name': gene_name,
                                'functional_term': go_term,
                                'extra_information': extra_info
                            })
                
                # Process KEGG KO terms
                if kegg_ko and kegg_ko != '-':
                    ko_list = kegg_ko.split(',')
                    for ko in ko_list:
                        ko = ko.strip()
                        # Remove 'ko:' prefix if present
                        if ko.startswith(self.KEGG_PREFIX):
                            ko = ko[self.KEGG_PREFIX_LEN:]
                        if ko:
                            extra_parts = []
                            if protein_name and protein_name != '-':
                                extra_parts.append(f"Protein: {protein_name}")
                            if description and description != '-':
                                extra_parts.append(f"Description: {description}")
                            
                            extra_info = "; ".join(extra_parts)
                            
                            self.results.append({
                                'gene_name': gene_name,
                                'functional_term': ko,
                                'extra_information': extra_info
                            })


class FantasiaParser(AnnotationParser):
    """Parser for FANTASIA AI-driven annotation output files"""
    
    # Model names mapping for output file naming
    MODEL_NAMES = {
        'ESM_L0': 'ESM-2',
        'Prot-T5_L0': 'ProtT5',
        'Prost-T5_L0': 'ProstT5',
        'Ankh3-Large_L0': 'Ankh3-Large',
        'ESM3c_L0': 'ESM3c'
    }
    
    def __init__(self, input_file: str, model_suffix: str = None):
        """
        Initialize parser with optional model suffix to filter specific model
        
        Args:
            input_file: Path to FANTASIA output TSV file
            model_suffix: If specified, only parse data for this model (e.g., 'ESM_L0')
        """
        super().__init__(input_file)
        self.model_suffix = model_suffix
    
    def parse(self):
        """
        Parse FANTASIA TSV format:
        Columns: accession, go_id, final_score_<model>, proteins
        Creates results with gene_name, GO, final_score, proteins
        """
        self.results = []
        
        if not os.path.exists(self.input_file):
            print(f"Warning: File not found: {self.input_file}")
            return
        
        with open(self.input_file, 'r') as f:
            header_line = None
            for line in f:
                # Skip comments
                if line.startswith('#'):
                    continue
                
                # First non-comment line is header
                if header_line is None:
                    header_line = line.strip().split('\t')
                    # Validate required columns exist
                    required_cols = ['accession', 'go_id', 'proteins']
                    if not all(col in header_line for col in required_cols):
                        print(f"Warning: Missing required columns in {self.input_file}")
                        print(f"Expected: {required_cols}")
                        return
                    continue
                
                parts = line.strip().split('\t')
                
                # Skip lines that don't match header length
                if len(parts) != len(header_line):
                    continue
                
                # Create dictionary from header and values
                row_dict = dict(zip(header_line, parts))
                
                accession = row_dict.get('accession', '')
                go_id = row_dict.get('go_id', '')
                proteins = row_dict.get('proteins', '')
                
                # Skip if no GO term
                if not go_id or go_id == '-':
                    continue
                
                # Get final_score for the specific model
                score_col = f'final_score_{self.model_suffix}' if self.model_suffix else None
                final_score = row_dict.get(score_col, '') if score_col else ''
                
                # Skip if this model has no score for this entry
                if self.model_suffix and (not final_score or final_score.strip() == ''):
                    continue
                
                self.results.append({
                    'gene_name': accession,
                    'functional_term': go_id,
                    'extra_information': f"Score: {final_score}; Proteins: {proteins}" if final_score else f"Proteins: {proteins}"
                })
    
    def to_dataframe(self) -> pd.DataFrame:
        """Convert results to pandas DataFrame with FANTASIA-specific column names"""
        if not self.results:
            return pd.DataFrame(columns=['gene_name', 'GO', 'final_score', 'proteins'])
        
        df = pd.DataFrame(self.results)
        # Rename columns to match FANTASIA expected format
        df_fantasia = pd.DataFrame({
            'gene_name': df['gene_name'],
            'GO': df['functional_term'],
            'final_score': df['extra_information'].apply(lambda x: x.split('Score: ')[1].split(';')[0] if 'Score: ' in x else ''),
            'proteins': df['extra_information'].apply(lambda x: x.split('Proteins: ')[1] if 'Proteins: ' in x else '')
        })
        return df_fantasia


def find_files(directory: str, pattern: str) -> List[str]:
    """Find files matching a pattern in a directory"""
    path = Path(directory)
    if not path.exists():
        return []
    
    files = []
    for file_path in path.glob(pattern):
        if file_path.is_file():
            files.append(str(file_path))
    
    return sorted(files)


def process_kofamscan(results_dir: str, output_dir: str):
    """Process all KofamScan output files"""
    print("\n" + "="*60)
    print("Processing KofamScan Results")
    print("="*60)
    
    kofam_dir = os.path.join(results_dir, 'kofamscan')
    if not os.path.exists(kofam_dir):
        print(f"Warning: KofamScan directory not found: {kofam_dir}")
        return
    
    # Find all mapper files
    mapper_files = find_files(kofam_dir, '*_kofam_mapper.tsv')
    
    if not mapper_files:
        print("No KofamScan mapper files found")
        return
    
    print(f"Found {len(mapper_files)} KofamScan file(s)")
    
    for mapper_file in mapper_files:
        basename = os.path.basename(mapper_file).replace('_kofam_mapper.tsv', '')
        output_file = os.path.join(output_dir, f"{basename}_kofamscan_annotations.xlsx")
        
        parser = KofamScanParser(mapper_file)
        parser.parse()
        parser.save_to_excel(output_file)


def process_interproscan(results_dir: str, output_dir: str):
    """Process all InterProScan output files"""
    print("\n" + "="*60)
    print("Processing InterProScan Results")
    print("="*60)
    
    interpro_dir = os.path.join(results_dir, 'interproscan')
    if not os.path.exists(interpro_dir):
        print(f"Warning: InterProScan directory not found: {interpro_dir}")
        return
    
    # Find all TSV files
    tsv_files = find_files(interpro_dir, '*.tsv')
    
    if not tsv_files:
        print("No InterProScan TSV files found")
        return
    
    print(f"Found {len(tsv_files)} InterProScan file(s)")
    
    for tsv_file in tsv_files:
        basename = os.path.basename(tsv_file).replace('.tsv', '')
        output_file = os.path.join(output_dir, f"{basename}_interproscan_annotations.xlsx")
        
        parser = InterProScanParser(tsv_file)
        parser.parse()
        parser.save_to_excel(output_file)


def process_eggnog(results_dir: str, output_dir: str):
    """Process all EggNOG-mapper output files"""
    print("\n" + "="*60)
    print("Processing EggNOG-mapper Results")
    print("="*60)
    
    # Check for both v5 and v7 outputs
    eggnog_v5_dir = os.path.join(results_dir, 'eggnog', 'v5')
    eggnog_v7_dir = os.path.join(results_dir, 'eggnog7')
    
    # Process v5 outputs
    if os.path.exists(eggnog_v5_dir):
        print("\nProcessing EggNOG v5 outputs...")
        # Find annotation files in subdirectories
        annotation_files = []
        for root, dirs, files in os.walk(eggnog_v5_dir):
            for file in files:
                if file.endswith('.emapper.annotations'):
                    annotation_files.append(os.path.join(root, file))
        
        if annotation_files:
            print(f"Found {len(annotation_files)} EggNOG v5 annotation file(s)")
            for annot_file in annotation_files:
                # Extract sample name from path
                basename = os.path.basename(annot_file).replace('.emapper.annotations', '')
                output_file = os.path.join(output_dir, f"{basename}_eggnog_v5_annotations.xlsx")
                
                parser = EggNOGParser(annot_file)
                parser.parse()
                parser.save_to_excel(output_file)
        else:
            print("No EggNOG v5 annotation files found")
    
    # Process v7 outputs
    if os.path.exists(eggnog_v7_dir):
        print("\nProcessing EggNOG v7 outputs...")
        tsv_gz_files = find_files(eggnog_v7_dir, '*.eggnog.tsv.gz')
        
        if tsv_gz_files:
            print(f"Found {len(tsv_gz_files)} EggNOG v7 annotation file(s)")
            for tsv_gz_file in tsv_gz_files:
                basename = os.path.basename(tsv_gz_file).replace('.eggnog.tsv.gz', '')
                output_file = os.path.join(output_dir, f"{basename}_eggnog_v7_annotations.xlsx")
                
                parser = EggNOG7Parser(tsv_gz_file)
                parser.parse()
                parser.save_to_excel(output_file)
        else:
            print("No EggNOG v7 annotation files found")
    
    if not os.path.exists(eggnog_v5_dir) and not os.path.exists(eggnog_v7_dir):
        print("Warning: No EggNOG directories found")


def process_fantasia(results_dir: str, output_dir: str):
    """Process all FANTASIA output files and create one Excel per model"""
    print("\n" + "="*60)
    print("Processing FANTASIA Results")
    print("="*60)
    
    fantasia_dir = os.path.join(results_dir, 'fantasia')
    if not os.path.exists(fantasia_dir):
        print(f"Warning: FANTASIA directory not found: {fantasia_dir}")
        return
    
    # Find all TSV files (FANTASIA outputs)
    tsv_files = find_files(fantasia_dir, '*.tsv')
    
    if not tsv_files:
        print("No FANTASIA TSV files found")
        return
    
    print(f"Found {len(tsv_files)} FANTASIA file(s)")
    
    # Define the models to process
    models = ['ESM_L0', 'Prot-T5_L0', 'Prost-T5_L0', 'Ankh3-Large_L0', 'ESM3c_L0']
    
    for tsv_file in tsv_files:
        basename = os.path.basename(tsv_file).replace('.tsv', '')
        
        # Process each model separately
        for model_suffix in models:
            model_name = FantasiaParser.MODEL_NAMES.get(model_suffix, model_suffix)
            output_file = os.path.join(output_dir, f"{basename}_fantasia_{model_name}_annotations.xlsx")
            
            parser = FantasiaParser(tsv_file, model_suffix=model_suffix)
            parser.parse()
            
            # Only save if there are results for this model
            if parser.results:
                parser.save_to_excel(output_file)
            else:
                print(f"  Skipping {model_name}: No annotations found")


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Generate Excel files from functional annotation outputs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process all results in default directories
  %(prog)s

  # Specify custom results and output directories
  %(prog)s -r /path/to/results -o /path/to/output

  # Process only specific tools
  %(prog)s --kofamscan-only
  %(prog)s --interproscan-only
  %(prog)s --eggnog-only
  %(prog)s --fantasia-only
        """
    )
    
    parser.add_argument(
        '-r', '--results-dir',
        default='../../results',
        help='Results directory containing tool outputs (default: ../../results)'
    )
    
    parser.add_argument(
        '-o', '--output-dir',
        default='./excel_outputs',
        help='Output directory for Excel files (default: ./excel_outputs)'
    )
    
    parser.add_argument(
        '--kofamscan-only',
        action='store_true',
        help='Process only KofamScan results'
    )
    
    parser.add_argument(
        '--interproscan-only',
        action='store_true',
        help='Process only InterProScan results'
    )
    
    parser.add_argument(
        '--eggnog-only',
        action='store_true',
        help='Process only EggNOG-mapper results'
    )
    
    parser.add_argument(
        '--fantasia-only',
        action='store_true',
        help='Process only FANTASIA results'
    )
    
    args = parser.parse_args()
    
    # Resolve paths
    results_dir = os.path.abspath(args.results_dir)
    output_dir = os.path.abspath(args.output_dir)
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    print("="*60)
    print("Functional Annotation Pipeline - Excel Output Generator")
    print("="*60)
    print(f"Results directory: {results_dir}")
    print(f"Output directory:  {output_dir}")
    print()
    
    if not os.path.exists(results_dir):
        print(f"Error: Results directory not found: {results_dir}")
        sys.exit(1)
    
    # Process tools based on flags
    process_all = not any([args.kofamscan_only, args.interproscan_only, args.eggnog_only, args.fantasia_only])
    
    if process_all or args.kofamscan_only:
        process_kofamscan(results_dir, output_dir)
    
    if process_all or args.interproscan_only:
        process_interproscan(results_dir, output_dir)
    
    if process_all or args.eggnog_only:
        process_eggnog(results_dir, output_dir)
    
    if process_all or args.fantasia_only:
        process_fantasia(results_dir, output_dir)
    
    print("\n" + "="*60)
    print("Excel Generation Complete")
    print("="*60)
    print(f"Output files saved to: {output_dir}")
    print()


if __name__ == '__main__':
    main()
