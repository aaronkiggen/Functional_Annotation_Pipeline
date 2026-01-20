#!/bin/bash -l
#SBATCH --clusters=wice
#SBATCH --partition=gpu_a100
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --ntasks-per-node=18
#SBATCH --mem=64G
#SBATCH --time=08:00:00
#SBATCH --job-name=06_fantasia
#SBATCH --output=logs/fantasia_%j.out
#SBATCH --error=logs/fantasia_%j.err

# NOTE: Paths here are specific to WICE cluster and containers
PROJECT_DIR="/lustre1/scratch/354/vsc35429/fantasia/FANTASIA"
IMG_DIR="$PROJECT_DIR/images"
EXEC_DIR="$PROJECT_DIR/fantasia"
LOG_DIR="$EXEC_DIR/logs"

PGVECTOR_IMAGE="$IMG_DIR/pgvector.sif"
RABBITMQ_IMAGE="$IMG_DIR/rabbitmq.sif"
FANTASIA_IMAGE="$IMG_DIR/fantasia.sif"
CONFIG_FILE="$PROJECT_DIR/fantasia/config.yaml"

mkdir -p "$LOG_DIR"
cd "$PROJECT_DIR" || exit 1

# Services Setup
RABBITMQ_DATA_DIR="$EXEC_DIR/rabbitmq"
PGDATA_HOST="$EXEC_DIR/pgdata_pgvector"
PG_RUN="$EXEC_DIR/pg_run"
mkdir -p "$RABBITMQ_DATA_DIR" "$PGDATA_HOST" "$PG_RUN"

echo "[INFO] Starting Services..."
nohup apptainer run --env POSTGRES_USER=usuario --env POSTGRES_PASSWORD=clave --env POSTGRES_DB="BioData" --bind "$PGDATA_HOST:/var/lib/postgresql/data" --bind "$PG_RUN:/var/run/postgresql" "$PGVECTOR_IMAGE" > "$LOG_DIR/postgres.log" 2>&1 &
nohup apptainer run --bind "$RABBITMQ_DATA_DIR:/var/lib/rabbitmq" "$RABBITMQ_IMAGE" > "$LOG_DIR/rabbitmq.log" 2>&1 &

sleep 30

echo "[INFO] Running Fantasia..."
apptainer exec --nv --bind "$EXEC_DIR:/fantasia" --bind "$PROJECT_DIR:/project" "$FANTASIA_IMAGE" fantasia run --config "/project/fantasia/config.yaml"

# Cleanup
cleanup() {
  pkill -f "$PGDATA_HOST" || true
  pkill -f "rabbitmq-server" || true
}
trap cleanup EXIT
