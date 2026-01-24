# Installation Scripts

This directory contains installation scripts for setting up the Functional Annotation Pipeline on your HPC cluster.

## Prerequisites

- Access to an HPC cluster with SLURM
- Conda/Mamba package manager installed
- Internet access for downloading databases
- Sufficient disk space (~50GB for databases)

## Important Note

**These scripts are designed to be run on the login node** of your HPC cluster, not on compute nodes. They download and configure databases and environments that will be used by the analysis jobs.

## Configuration

Before running any installation scripts, **edit `config.env`** in the root directory to set your paths correctly:

```bash
cd ..
nano config.env
```

Key variables to configure:
- `PROJECT_ROOT`: Root directory of the pipeline
- `DB_ROOT`: Where databases will be stored (default: `${HOME}/databases`)
- `INTERPROSCAN_HOME`: InterProScan installation path
- `EGGNOG7_SCRIPT`: EggNOG7 annotator script path

## Installation Order

Follow these steps in order:

### 1. Environments and Databases (Main Script)

This is the primary installation script that sets up Conda environments and downloads databases for KofamScan, EggNOG-mapper (v5 & v7), and OrthoFinder.

```bash
./environments_and_databases
```

**What it does:**
- Creates Conda environments: `kofam`, `eggnog_2025`, `of3`
- Downloads KofamScan database (~2GB)
- Downloads EggNOG v5 database (~4-10GB depending on options)
- Downloads EggNOG v7 database (~5GB)

**Time estimate:** 1-3 hours (depending on network speed)

### 2. InterProScan

Install InterProScan for domain and motif analysis:

```bash
./interproscan
```

**What it does:**
- Downloads InterProScan 5.76-107.0 (~11GB)
- Extracts and indexes HMM models
- Runs a test to verify installation

**Time estimate:** 30-60 minutes

### 3. EggNOG7 Annotator

Install the EggNOG7 annotator tool:

```bash
./eggnog7_annotator
```

**What it does:**
- Clones the eggnog7_annotator repository
- Sets up PATH for the annotator script

**Time estimate:** < 5 minutes

### 4. FANTASIA (Optional)

FANTASIA is for AI-driven annotation using GPUs. This script provides instructions rather than automated installation:

```bash
./FANTASIA
```

**What it provides:**
- Step-by-step instructions for setting up FANTASIA
- Configuration guidance
- Links to documentation

**Note:** FANTASIA requires GPU resources and is more complex. Follow the interactive guide carefully.

## Script Features

All scripts now:
- ✓ Source `config.env` for consistent path configuration
- ✓ Display clear progress messages
- ✓ Show what's happening at each step
- ✓ Include installation summaries
- ✓ Provide next steps and verification commands

## Verification

After installation, verify that everything works:

```bash
# Test KofamScan
conda activate kofam
exec_annotation --help

# Test EggNOG-mapper
conda activate eggnog_2025
emapper.py --version

# Test OrthoFinder
conda activate of3
orthofinder --help

# Test InterProScan
${INTERPROSCAN_HOME}/interproscan.sh --help

# Test EggNOG7 annotator
${EGGNOG7_SCRIPT} -h
```

## Troubleshooting

### Conda environments not activating
Make sure Conda is properly initialized:
```bash
conda init bash
source ~/.bashrc
```

### Database downloads failing
- Check your internet connection
- Try using `wget` with `--no-check-certificate` if SSL errors occur
- Verify you have sufficient disk space

### Permission errors
Make sure scripts are executable (run from project root):
```bash
chmod +x installation/environments_and_databases installation/interproscan installation/eggnog7_annotator installation/FANTASIA
```

## Additional Resources

- [Pipeline README](../README.md) - Main pipeline documentation
- [Documentation Directory](../docs/) - Detailed guides for each tool
- [EggNOG-mapper docs](https://github.com/eggnogdb/eggnog-mapper/wiki)
- [InterProScan docs](https://interproscan-docs.readthedocs.io/)
- [FANTASIA docs](https://fantasia.readthedocs.io/)

## Support

If you encounter issues:
1. Check the error messages carefully
2. Verify your `config.env` settings
3. Consult the tool-specific documentation
4. Open an issue on GitHub: https://github.com/aaronkiggen/Functional_Annotation_Pipeline/issues
