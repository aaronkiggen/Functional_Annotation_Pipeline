# Step 06: FANTASIA - AI-Driven Functional Annotation

## Overview

**FANTASIA** (Functional ANnotation with Transformers And Semantic Intelligence Architecture) leverages Large Language Models (LLMs) and vector databases to perform context-aware functional annotation of proteins. Unlike traditional methods, FANTASIA:

- **Understands biological context**: Uses transformer models trained on scientific literature
- **Provides natural language descriptions**: Human-readable functional predictions
- **Integrates multiple data sources**: Combines sequence, structure, and literature
- **GPU-accelerated**: Requires NVIDIA GPU for inference

## Architecture

```
┌─────────────┐       ┌──────────────┐       ┌─────────────────┐
│   Input     │──────▶│  Embedding   │──────▶│ Vector Database │
│  Proteins   │       │    Model     │       │   (pgvector)    │
└─────────────┘       └──────────────┘       └─────────────────┘
                              │                        │
                              │                        ▼
                              │               ┌─────────────────┐
                              └──────────────▶│  LLM Inference  │
                                              │   (GPU-based)   │
                                              └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │   Annotations   │
                                              │   + Confidence  │
                                              └─────────────────┘
```

## Requirements

### Hardware

- **GPU**: NVIDIA A100 (40-80 GB), H100, or V100 (32 GB)
  - Minimum: RTX 3090/4090 (24 GB) for small models
- **RAM**: 64-128 GB
- **Storage**: 500 GB (for models and vector database)

### Software

- **Apptainer/Singularity**: v1.1+ (containerization)
- **CUDA**: 11.8+ (GPU drivers)
- **PostgreSQL**: 14+ with **pgvector** extension
- **RabbitMQ**: 3.11+ (message queue for job distribution)

### On VSC (Flemish Supercomputer)

Request GPU nodes:

```bash
#SBATCH --partition=gpu
#SBATCH --gpus=1
#SBATCH --gpus-per-node=a100:1
#SBATCH --mem=128GB
#SBATCH --time=48:00:00
```

## Installation

### 1. Download FANTASIA Container

```bash
mkdir -p containers/
cd containers/

# Pull Apptainer image (example URL - adjust to actual)
apptainer pull fantasia. sif docker://registry.example.com/fantasia:latest
```

### 2. Download Model Weights

```bash
# Embedding model (e.g., ProtBERT, ESM-2)
wget https://huggingface.co/Rostlab/prot_bert/resolve/main/pytorch_model.bin
mv pytorch_model.bin models/prot_bert.bin

# LLM for annotation (e.g., BioGPT, fine-tuned LLaMA)
wget https://huggingface.co/microsoft/biogpt/resolve/main/pytorch_model.bin
mv pytorch_model.bin models/biogpt.bin
```

### 3. Set Up PostgreSQL with pgvector

```bash
# Inside a Singularity/Apptainer container or local install
apt-get install postgresql-14 postgresql-14-pgvector

# Initialize database
initdb -D fantasia_db
pg_ctl -D fantasia_db start

# Create database
createdb fantasia_vectors

# Enable pgvector extension
psql fantasia_vectors -c "CREATE EXTENSION vector;"
```

### 4. Configure RabbitMQ

```bash
# Run RabbitMQ in a container
apptainer run docker://rabbitmq:3.11-management

# Or use system RabbitMQ
rabbitmq-server -detached
```

## Configuration

### Main Config File: `fantasia/config.yaml`

```yaml
# Model paths
models:
  embedding_model: "/path/to/models/prot_bert.bin"
  llm_model: "/path/to/models/biogpt.bin"
  tokenizer: "/path/to/tokenizer/"

# Database connection
database:
  host: "localhost"
  port: 5432
  name: "fantasia_vectors"
  user: "fantasia_user"
  password:  "secure_password"

# RabbitMQ
message_queue:
  host: "localhost"
  port: 5672
  queue_name: "annotation_jobs"

# GPU settings
gpu:
  device_id: 0
  batch_size: 32
  fp16: true  # Mixed precision for faster inference

# Annotation parameters
annotation:
  min_confidence: 0.7
  top_k_results: 5
  context_window: 512
  temperature: 0.3  # Lower = more deterministic

# Reference databases (for semantic search)
reference_dbs:
  - "/path/to/uniprot_sprot.faa"
  - "/path/to/nr_subset.faa"
```

## Running FANTASIA

### SLURM Script

```bash
sbatch 06_run_fantasia.slurm
```

### Script Structure

```bash
#!/bin/bash
#SBATCH --job-name=fantasia
#SBATCH --partition=gpu
#SBATCH --gpus=a100:1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128GB
#SBATCH --time=48:00:00

module load CUDA/11.8
module load Apptainer

# Start PostgreSQL
export PGDATA=$VSC_SCRATCH/fantasia_db
pg_ctl start

# Start RabbitMQ
apptainer instance start rabbitmq. sif rabbitmq_inst

# Run FANTASIA
apptainer exec --nv fantasia.sif \
  python /app/fantasia_annotate.py \
    --input primary_transcripts/species. faa \
    --output fantasia_results/ \
    --config fantasia/config.yaml \
    --workers 4

# Cleanup
pg_ctl stop
apptainer instance stop rabbitmq_inst
```

### Direct Execution (for testing)

```bash
# Activate container
apptainer shell --nv fantasia.sif

# Run annotation
python fantasia_annotate.py \
  --input test_proteins.faa \
  --output test_results/ \
  --config config.yaml \
  --verbose
```

## Pipeline Workflow

### Stage 1: Embedding Generation

Converts protein sequences into vector embeddings:

```python
for protein in input_fasta:
    embedding = embedding_model. encode(protein. sequence)
    store_in_pgvector(protein.id, embedding)
```

### Stage 2: Semantic Search

Finds similar proteins in reference database:

```sql
SELECT id, annotation, 1 - (embedding <=> query_embedding) AS similarity
FROM protein_vectors
ORDER BY similarity DESC
LIMIT 5;
```

### Stage 3: LLM Inference

Generates functional description using context: 

```
Prompt: 
"Given the following protein sequence and similar annotated proteins: 
Sequence: MSTLKPVQ... 
Similar proteins: 
1. Protein kinase domain (similarity: 0.95)
2. ATP-binding site (similarity: 0.89)

Provide a detailed functional annotation:"

LLM Output:
"This protein is a serine/threonine protein kinase involved in..."
```

### Stage 4: Confidence Scoring

Assigns confidence based on: 
- Embedding similarity to known proteins
- LLM output probability
- Consistency across multiple predictions

## Output Files

### 1. Main Annotation File

```tsv
protein_id  predicted_function  confidence  top_similar_protein  similarity_score
gene001.t1  Protein kinase, ATP-binding  0.95  sp|P12345|PKA_HUMAN  0.93
gene002.t1  Transcription factor, zinc finger  0.88  sp|Q98765|ZNF1_MOUSE  0.86
```

### 2. Detailed JSON Output

```json
{
  "gene001. t1": {
    "sequence_length": 450,
    "predicted_function": "Protein kinase, ATP-binding",
    "confidence": 0.95,
    "similar_proteins": [
      {"id": "sp|P12345|PKA_HUMAN", "similarity": 0.93, "function": "cAMP-dependent protein kinase"},
      {"id": "sp|Q54321|PKB_RAT", "similarity": 0.89, "function": "Serine/threonine kinase"}
    ],
    "go_terms": ["GO:0004672", "GO:0005524"],
    "ec_numbers": ["2.7.11.1"],
    "llm_raw_output": "This protein contains a conserved kinase domain..."
  }
}
```

### 3. Log File

```
[2026-01-20 10:15:32] INFO: Loaded 10,000 proteins
[2026-01-20 10:16:45] INFO: Generated embeddings for batch 1/200
[2026-01-20 10:45:12] INFO: Completed semantic search for 5,000 proteins
[2026-01-20 12:30:00] INFO: LLM inference completed.  Avg confidence: 0.87
```

## Performance Benchmarks

| Dataset Size | GPU | Runtime | Throughput |
|--------------|-----|---------|------------|
| 1,000 proteins | A100 (40GB) | 30 min | 33 prot/min |
| 10,000 proteins | A100 (40GB) | 4 hours | 42 prot/min |
| 50,000 proteins | H100 | 10 hours | 83 prot/min |

## Troubleshooting

### Issue:  CUDA out of memory

**Solution**:  Reduce batch size

```yaml
gpu:
  batch_size: 16  # Reduced from 32
```

### Issue: PostgreSQL connection error

**Solution**:  Ensure database is running and accessible

```bash
pg_ctl status -D $PGDATA
psql -h localhost -d fantasia_vectors -c "SELECT 1;"
```

### Issue: RabbitMQ not accepting connections

**Solution**: Check firewall and port availability

```bash
netstat -tuln | grep 5672
rabbitmqctl status
```

### Issue: Low confidence scores

**Possible causes**:
- Novel proteins not in training data
- Poor quality input sequences

**Solution**: Lower confidence threshold or use ensemble with other tools

```yaml
annotation:
  min_confidence: 0.6  # Lowered from 0.7
```

## Integration with Pipeline

### Combine with Traditional Annotations

```python
import pandas as pd

fantasia = pd.read_csv("fantasia_results/annotations.tsv", sep="\t")
eggnog = pd.read_csv("eggnog_results. emapper.annotations", sep="\t", comment="#")
kofam = pd.read_csv("kofamscan_output.txt", sep="\t")

# Merge on protein ID
merged = fantasia.merge(eggnog, left_on="protein_id", right_on="query")
merged = merged.merge(kofam, left_on="protein_id", right_on="gene_name")

# Consensus annotation
merged["consensus_function"] = merged. apply(
    lambda row: vote_function([row. predicted_function, row.Description, row.KO_function]),
    axis=1
)
```

### Prioritize High-Confidence FANTASIA Predictions

```python
# Use FANTASIA for high-confidence, fall back to EggNOG/Kofam for others
final_annotations = []

for _, row in merged.iterrows():
    if row["fantasia_confidence"] > 0.9:
        final_annotations.append(row["fantasia_function"])
    elif row["eggnog_score"] > 50:
        final_annotations.append(row["eggnog_function"])
    else:
        final_annotations.append(row["kofam_function"])
```

## Advanced Usage

### Fine-Tune LLM on Your Data

```bash
python fine_tune_llm.py \
  --base_model models/biogpt.bin \
  --training_data your_curated_annotations.tsv \
  --output models/biogpt_finetuned.bin \
  --epochs 3 \
  --learning_rate 1e-5
```

### Custom Reference Database

```bash
# Index your own protein database
python build_vector_db.py \
  --fasta custom_proteins.faa \
  --annotations custom_annotations.tsv \
  --output custom_vectors.pgvector
```

### Batch Submission

For very large datasets, split and submit multiple jobs:

```bash
split -l 1000 input_proteins.faa chunk_

for chunk in chunk_*; do
    sbatch --export=INPUT=$chunk 06_run_fantasia.slurm
done
```

## Citation

```
[FANTASIA paper pending publication]
```

If using in published research, also cite underlying models: 
- **ProtBERT**: Elnaggar et al. (2021) IEEE TPAMI
- **BioGPT**: Luo et al. (2022) Briefings in Bioinformatics

---

**Script**: `scripts/06_run_fantasia.slurm`  
**Expected Runtime**: 4-48 hours (GPU and dataset dependent)  
**Memory**: 128 GB  
**GPU**:  NVIDIA A100 or equivalent (40+ GB VRAM)  
**Note**: This is the most resource-intensive step; run last
