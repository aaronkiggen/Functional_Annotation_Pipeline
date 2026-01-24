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

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE_ENV="${SCRIPT_DIR}/../config.env"

if [ -f "${CONFIG_FILE_ENV}" ]; then
    source "${CONFIG_FILE_ENV}"
    echo "✓ Loaded configuration from ${CONFIG_FILE_ENV}"
else
    echo "ERROR: Configuration file not found: ${CONFIG_FILE_ENV}"
    exit 1
fi

# Variables derived from config.env
PROJECT_DIR="${PROJECT_ROOT}"
IMG_DIR="$(dirname "${FANTASIA_CONTAINER}")"
EXEC_DIR="${PROJECT_ROOT}/fantasia"
# LOG_DIR is already set in config.env

PGVECTOR_IMAGE="${IMG_DIR}/pgvector.sif"
RABBITMQ_IMAGE="${IMG_DIR}/rabbitmq.sif"
FANTASIA_IMAGE="${FANTASIA_CONTAINER}"
CONFIG_FILE="${FANTASIA_CONFIG}"

mkdir -p "$LOG_DIR"
cd "$PROJECT_DIR" || exit 1

# Services Setup
RABBITMQ_DATA_DIR="${EXEC_DIR}/rabbitmq"
PGDATA_HOST="${FANTASIA_PGDATA}"
PG_RUN="${EXEC_DIR}/pg_run"
mkdir -p "$RABBITMQ_DATA_DIR" "$PGDATA_HOST" "$PG_RUN"

mkdir -p "$IMG_DIR"


# =======================
# Build containers if not present
# =======================
if [ ! -f "$PGVECTOR_IMAGE" ]; then
    echo "Building pgvector container..."
    apptainer build "$PGVECTOR_IMAGE" docker://pgvector/pgvector:pg16
fi

if [ ! -f "$RABBITMQ_IMAGE" ]; then
    echo "Building RabbitMQ container..."
    apptainer build "$RABBITMQ_IMAGE" docker://rabbitmq:management
fi

if [ ! -f "$FANTASIA_IMAGE" ]; then
    echo "Building FANTASIA container..."
    apptainer build --disable-cache "$FANTASIA_IMAGE" docker://frapercan/fantasia:latest
fi


echo "[INFO] Starting Services..."
nohup apptainer run --env POSTGRES_USER="${FANTASIA_DB_USER}" --env POSTGRES_PASSWORD="${FANTASIA_DB_PASSWORD}" --env POSTGRES_DB="${FANTASIA_DB_NAME}" --bind "$PGDATA_HOST:/var/lib/postgresql/data" --bind "$PG_RUN:/var/run/postgresql" "$PGVECTOR_IMAGE" > "$LOG_DIR/postgres.log" 2>&1 &
nohup apptainer run --bind "$RABBITMQ_DATA_DIR:/var/lib/rabbitmq" "$RABBITMQ_IMAGE" > "$LOG_DIR/rabbitmq.log" 2>&1 &

sleep 30


echo "[INFO] Initialize Fantasia..."
apptainer exec --nv --bind "$EXEC_DIR:/fantasia" "$FANTASIA_IMAGE" fantasia initialize

echo "[INFO] Running Fantasia..."
apptainer exec --nv --bind "$EXEC_DIR:/fantasia" --bind "${PROJECT_ROOT}:/project" "$FANTASIA_IMAGE" fantasia run --config "/project/fantasia/config.yaml"

# Cleanup
cleanup() {
  pkill -f "$PGDATA_HOST" || true
  pkill -f "rabbitmq-server" || true
}
trap cleanup EXIT
