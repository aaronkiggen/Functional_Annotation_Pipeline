# EggNOG Output Column Interpretation

This document explains the columns in the EggNOG annotation output files.

## Column Descriptions

| Column | Example Value | Description |
|--------|---------------|-------------|
| 1 | `KAK4002049.1` | **Query sequence ID** — your protein ID from the input FASTA. |
| 2 | `35525.A0A0P5P4T6` | **EggNOG protein ID** — the matched protein in the EggNOG database. |
| 3 | `100` | **Percent identity** — % of identical amino acids in the alignment. |
| 4 | `424` | **Alignment length** — number of aligned amino acids. |
| 5 | `1.53E-300` | **E-value** — significance of the match. Smaller is better. |
| 6 | `821` | **Bit score** — alignment score reported by Diamond. Higher = better. |
| 7 | `PID@33154` | **Dl-11** |
| 8 | `PID` | **Cluster category/type** — often EggNOG functional category abbreviation. |
| 9 | `33208` | **Seed ortholog ID** — ID of the representative protein in the cluster. |
| 10 | `1267` | **Query length** — length of your input protein sequence. |
| 11 | `456` | **Subject length** — length of the matched EggNOG protein. |
| 12 | `35525.A0A0P5P4T6` | **EggNOG sequence ID repeated** (sometimes used in merging steps). |
| 13 | `K06057` | **KEGG TERM + SCORE** |
| 14 | `NUMBL` | **NUMBL PROTEIN** |
| 15 | `GO:0048856` | **GO TERM + SCORE** |
| 16 | `Metazoa` | **Taxonomic level assigned** — e.g., kingdom, phylum. |
| 17 | `kingdom` | **Taxonomic rank** — e.g., kingdom, phylum, class. |
| 18 | `root,cellular organisms,Eukaryota,Opisthokonta,Metazoa` | **Full taxonomy path** — comma-separated from root to taxon. |

## Score Interpretation

> **Note:** The number after the `|` pipe symbol is not an E-value or p-value, but rather a **score** reflecting the weight, contribution, or confidence of that annotation for your protein.
