# Step 06: FANTASIA - AI-Driven Annotation

GPU-accelerated functional annotation using Large Language Models (LLMs) and vector databases for context-aware protein annotation.

## Requirements

### Hardware
- **GPU**: NVIDIA A100 (40-80 GB), H100, or V100 (32 GB minimum)
- **RAM**: 64-128 GB
- **Storage**: 500 GB

### Software
- Apptainer/Singularity v1.1+
- CUDA 11.8+
- PostgreSQL 14+ with pgvector extension
- RabbitMQ 3.11+

## Installation

### 1. Get Container & Models
```bash
# Download FANTASIA container
apptainer pull fantasia.sif docker://registry.example.com/fantasia:latest

# Download model weights (ProtBERT, BioGPT, etc.)
# Place in models/ directory
```

### 2. Setup PostgreSQL with pgvector
```bash
# Initialize database
initdb -D fantasia_db
pg_ctl -D fantasia_db start

# Create database and enable pgvector
createdb fantasia_vectors
psql fantasia_vectors -c "CREATE EXTENSION vector;"
```

### 3. Configure RabbitMQ
```bash
apptainer run docker://rabbitmq:3.11-management
# or use system RabbitMQ
```

## Configuration

Edit `fantasia/config.yaml`:
```yaml
models:
  embedding_model: "/path/to/prot_bert.bin"
  llm_model: "/path/to/biogpt.bin"

database:
  host: "localhost"
  port: 5432
  name: "fantasia_vectors"

gpu:
  device_id: 0
  batch_size: 32
  fp16: true

annotation:
  min_confidence: 0.7
  top_k_results: 5
  temperature: 0.3
```

## Usage

```bash
sbatch 06_run_fantasia.slurm
```

**Resources**: A100 GPU, 16 CPUs, 128 GB RAM, 4-48 hours

### Command
```bash
apptainer exec --nv fantasia.sif \
  python fantasia_annotate.py \
    --input proteins.faa \
    --output results/ \
    --config config.yaml \
    --workers 4
```

## Output

### Main Annotation File (TSV)
```
protein_id  predicted_function         confidence  top_similar_protein
gene001.t1  Protein kinase, ATP-bind  0.95        sp|P12345|PKA_HUMAN
```

### Detailed JSON Output
```json
{
  "gene001.t1": {
    "predicted_function": "Protein kinase, ATP-binding",
    "confidence": 0.95,
    "similar_proteins": [...],
    "go_terms": ["GO:0004672"],
    "ec_numbers": ["2.7.11.1"]
  }
}
```

## Performance

| Dataset Size | GPU | Runtime | Throughput |
|--------------|-----|---------|------------|
| 1,000 | A100 40GB | 30 min | 33 prot/min |
| 10,000 | A100 40GB | 4 hours | 42 prot/min |
| 50,000 | H100 | 10 hours | 83 prot/min |

## Troubleshooting

**CUDA out of memory**: Reduce `batch_size` in config (try 16)

**PostgreSQL connection error**: Check database is running with `pg_ctl status`

**RabbitMQ issues**: Verify port 5672 is accessible with `netstat -tuln | grep 5672`

**Low confidence scores**: Lower threshold to 0.6 or combine with other annotation tools

## Integration

Combine FANTASIA with traditional annotations:
```python
import pandas as pd

fantasia = pd.read_csv("fantasia_results/annotations.tsv", sep="\t")
eggnog = pd.read_csv("eggnog.emapper.annotations", sep="\t", comment="#")

# Merge and prioritize high-confidence FANTASIA predictions
merged = fantasia.merge(eggnog, left_on="protein_id", right_on="query")
```
