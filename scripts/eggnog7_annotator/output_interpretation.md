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

> **Note:** The number after the `|` pipe symbol is not an E-value or p-value, but rather a **score** reflecting the weight, contribution, or confidence of that annotation for your protein. Each term is assigned a confidence score that reflects how strongly and consistently that function is supported by phylogeny‑aware orthology evidence.

### 2. What the GO / KEGG score is actually based on

The score is not a simple BLAST score or hit count.
It is derived from four main components, all evaluated within phylogenetically consistent orthologous groups (OGs).

#### 2.1 Fraction of orthologs carrying the term (consistency)

For a given OG:

- eggNOG checks how many member proteins are annotated with a given GO or KEGG term
- The more consistently a term appears across orthologs, the higher the score

Conceptually:

```
score ∝ (# orthologs with term) / (total orthologs in OG)
```

A term found in:

- 95% of orthologs → high score
- 10% of orthologs → low score

This directly measures functional conservation. [[academic.oup.com](https://academic.oup.com)]

#### 2.2 Phylogenetic depth of support (evolutionary breadth)

Because v7 uses explicit gene trees, eggNOG can evaluate:

- At what evolutionary depth the function appears
- Whether it is conserved across:
  - multiple phyla / kingdoms
  - or only a recent lineage

Functions supported across deep speciation nodes get higher confidence than lineage‑specific ones. [[academic.oup.com](https://academic.oup.com)], [[bork.embl.de](https://bork.embl.de)]

This is a major upgrade over v5, which had no explicit tree‑based reasoning.

#### 2.3 Penalization of paralog‑specific or clade‑restricted terms

Using duplication/speciation inference, eggNOG v7 can detect:

Functions present only in:

- a paralog branch
- a subclade after duplication

These annotations:

- Are down‑weighted
- Receive lower scores because they are not ancestral to the full OG

This reduces false functional transfers between paralogs — a known problem in v5. [[academic.oup.com](https://academic.oup.com)], [[cbgp.upm.es](https://cbgp.upm.es)]

#### 2.4 Annotation source reliability (GO / KEGG evidence quality)

eggNOG v7 also accounts for annotation provenance, including:

- Curated vs automated sources
- Agreement across databases
- Redundancy of independent annotations

Terms supported by:

- Multiple curated annotations → higher score
- Single weak annotation → lower score

While eggNOG does not expose raw GO evidence codes, this weighting is part of the internal scoring model described in the v7 paper. [[academic.oup.com](https://academic.oup.com)]

### 3. What the score is not

Important to avoid misinterpretation:

❌ It is not:

- A probability of correctness
- A p‑value
- A BLAST or DIAMOND similarity score
- A measure of expression or activity

✅ It is:

- A relative confidence score for functional assignment
- Comparable within eggNOG v7, not across databases

### 4. How to interpret the scores in practice

While eggNOG does not publish a single hard cutoff, in practice:

| Score range | Interpretation |
|-------------|----------------|
| High (top tier) | Strongly conserved, ancestral function |
| Medium | Likely function, but clade‑restricted or partially conserved |
| Low | Weak, lineage‑specific, or uncertain transfer |

This makes it possible to:

- Filter GO / KEGG terms by confidence
- Prioritize annotations for downstream analyses
- Avoid over‑annotation in comparative genomics

Benchmarking against manually curated KEGG functional OGs showed that these scores correlate with higher functional consistency than v5 annotations. [[academic.oup.com](https://academic.oup.com)]

### 5. Why this matters for downstream analyses

**Functional enrichment**

- You can weight genes by annotation confidence
- Reduces noise in GO / KEGG enrichment

**Cross‑species comparisons**

- High‑score terms are safer for distant taxa
- Low‑score terms flag recent innovations

**Gene family evolution**

- Scores highlight where functions were gained or specialized after duplication

This is particularly relevant for eukaryotes and multidomain proteins, where v5 was weakest. [[cbgp.upm.es](https://cbgp.upm.es)]
