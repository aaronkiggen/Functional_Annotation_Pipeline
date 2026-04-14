#!/usr/bin/env Rscript
# ==============================================================================
# Script: 05_step3_gosemsim_metrics.R
# Description: Uses the GOSemSim package to compute Wang Semantic Similarity 
#              between GO terms provided by InterProScan, EggNOG, and others.
#              Replaces the old pure-Python custom script.
# ==============================================================================

# ------------------------------------------------------------------------------
# Package Installation & Loading
# ------------------------------------------------------------------------------
if (!requireNamespace("optparse", quietly = TRUE)) install.packages("optparse", repos="http://cran.us.r-project.org")
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager", repos="http://cran.us.r-project.org")
if (!requireNamespace("GOSemSim", quietly = TRUE)) BiocManager::install("GOSemSim", update=FALSE, ask=FALSE)
if (!requireNamespace("AnnotationDbi", quietly = TRUE)) BiocManager::install("AnnotationDbi", update=FALSE, ask=FALSE)
if (!requireNamespace("GO.db", quietly = TRUE)) BiocManager::install("GO.db", update=FALSE, ask=FALSE)
if (!requireNamespace("org.Hs.eg.db", quietly = TRUE)) BiocManager::install("org.Hs.eg.db", update=FALSE, ask=FALSE)

suppressPackageStartupMessages({
  library(optparse)
  library(GOSemSim)
  library(AnnotationDbi)
  library(GO.db)
})

# ------------------------------------------------------------------------------
# Arguments
# ------------------------------------------------------------------------------
option_list <- list(
  make_option(c("-e", "--eggnog"), type="character", default=NULL, help="EggNOG annotation file (.emapper.annotations)", metavar="character"),
  make_option(c("-i", "--ips"), type="character", default=NULL, help="InterProScan TSV output file", metavar="character"),
  make_option(c("-o", "--output"), type="character", default="go_similarity_results.csv", help="Output CSV file for metrics", metavar="character")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$eggnog) | is.null(opt$ips)){
  print_help(opt_parser)
  stop("At least --eggnog and --ips must be supplied.", call.=FALSE)
}

message("=========================================================")
message("       GO Semantic Similarity (Wang Method)              ")
message("=========================================================")

# ------------------------------------------------------------------------------
# Initialize GO SemData (Dummy OrgDb since Wang is species-independent via GO.db)
# ------------------------------------------------------------------------------
message("Initializing GO databases (BP, MF, CC)...")
go_bp <- godata("org.Hs.eg.db", ont="BP", computeIC=FALSE)
go_mf <- godata("org.Hs.eg.db", ont="MF", computeIC=FALSE)
go_cc <- godata("org.Hs.eg.db", ont="CC", computeIC=FALSE)

# ------------------------------------------------------------------------------
# Parsing Functions
# ------------------------------------------------------------------------------
parse_eggnog <- function(filepath) {
  message("Parsing EggNOG GO terms from: ", filepath)
  if(!file.exists(filepath)) return(list())
  
  # Read skipping comment lines
  lines <- readLines(filepath)
  lines <- lines[!startsWith(lines, "#")]
  if(length(lines) == 0) return(list())
  
  df <- read.csv(text=lines, sep="\t", header=FALSE, fill=TRUE, stringsAsFactors=FALSE, quote="")
  
  # EggNOG emapper v2 format generally has the Query in V1 and GOs in V10. 
  # If empty it usually has a "-"
  res <- df[df$V10 != "" & df$V10 != "-", c("V1", "V10")]
  colnames(res) <- c("Protein", "GO_Terms")
  
  # Process and flatten GO terms
  go_list <- list()
  for (i in 1:nrow(res)) {
    pid <- res$Protein[i]
    terms <- unlist(strsplit(res$GO_Terms[i], ","))
    terms <- trimws(terms)
    terms <- terms[grepl("^GO:", terms)]
    if(length(terms) > 0) go_list[[pid]] <- unique(terms)
  }
  return(go_list)
}

parse_ips <- function(filepath) {
  message("Parsing InterProScan GO terms from: ", filepath)
  if(!file.exists(filepath)) return(list())
  
  df <- tryCatch({
    read.csv(filepath, sep="\t", header=FALSE, fill=TRUE, stringsAsFactors=FALSE, quote="")
  }, error = function(e){ return(NULL) })
  
  if (is.null(df) || nrow(df) == 0) return(list())
  
  # IPS format: Col 1 is Query, Col 14 usually contains GOs (GO:0001234|GO:0005678)
  # But we must check safely if V14 exists
  if (ncol(df) < 14) return(list())
  
  res <- df[df$V14 != "" & grepl("GO:", df$V14), c("V1", "V14")]
  colnames(res) <- c("Protein", "GO_Terms")
  
  # Aggregate by protein
  go_list <- list()
  for (i in 1:nrow(res)) {
    pid  <- res$Protein[i]
    terms <- unlist(strsplit(res$GO_Terms[i], "\\|"))
    terms <- trimws(terms)
    terms <- terms[grepl("^GO:", terms)]
    
    if (length(terms) > 0) {
      if (is.null(go_list[[pid]])) {
        go_list[[pid]] <- terms
      } else {
        go_list[[pid]] <- c(go_list[[pid]], terms)
      }
    }
  }
  
  # Unique representations
  for (pid in names(go_list)) {
      go_list[[pid]] <- unique(go_list[[pid]])
  }
  
  return(go_list)
}

# ------------------------------------------------------------------------------
# Execution
# ------------------------------------------------------------------------------
egg_go <- parse_eggnog(opt$eggnog)
ips_go <- parse_ips(opt$ips)

common_prots <- intersect(names(egg_go), names(ips_go))
message(sprintf("Found %d proteins annotated by BOTH EggNOG and InterProScan with valid GO terms.", length(common_prots)))

if (length(common_prots) == 0) {
  message("No overlapping proteins found to compare. Generating empty results.")
  write.csv(data.frame(Protein_ID=character(), EggNOG_Count=integer(), IPS_Count=integer(), Wang_BMA_Similarity=numeric()), opt$output, row.names=FALSE)
  quit(status=0)
}

results <- data.frame(
  Protein_ID = character(length(common_prots)),
  EggNOG_Count = integer(length(common_prots)),
  IPS_Count = integer(length(common_prots)),
  Wang_BMA_Similarity = numeric(length(common_prots)),
  stringsAsFactors = FALSE
)

# Helper function to compute semantic similarity across all 3 sub-ontologies safely.
compute_wang_overall <- function(termsA, termsB) {
  sim_bp <- tryCatch({mgoSim(termsA, termsB, semData=go_bp, measure="Wang", combine="BMA")}, error=function(e) NA)
  sim_mf <- tryCatch({mgoSim(termsA, termsB, semData=go_mf, measure="Wang", combine="BMA")}, error=function(e) NA)
  sim_cc <- tryCatch({mgoSim(termsA, termsB, semData=go_cc, measure="Wang", combine="BMA")}, error=function(e) NA)
  
  scores <- c(sim_bp, sim_mf, sim_cc)
  scores <- scores[!is.na(scores)]
  
  if (length(scores) == 0) return(0.0)
  return(mean(scores)) # Average BMA across the matched sub-ontologies
}

message("Calculating topological Wang similarities (this is fast in C++ via GOSemSim)...")
for (i in seq_along(common_prots)) {
  pid <- common_prots[i]
  
  go1 <- egg_go[[pid]]
  go2 <- ips_go[[pid]]
  
  # Calculate
  overall_sim <- compute_wang_overall(go1, go2)
  
  results$Protein_ID[i] <- pid
  results$EggNOG_Count[i] <- length(go1)
  results$IPS_Count[i] <- length(go2)
  results$Wang_BMA_Similarity[i] <- round(overall_sim, 4)
  
  if (i %% 500 == 0) {
    message(sprintf("Processed %d / %d proteins...", i, length(common_prots)))
  }
}

mean_sim <- mean(results$Wang_BMA_Similarity, na.rm=TRUE)
message("\n===============================")
message("          QC SUMMARY           ")
message("===============================")
message(sprintf("Proteins Compared:         %d", length(common_prots)))
message(sprintf("Average Wang Similarity:   %.3f", mean_sim))
message("===============================\n")

write.csv(results, opt$output, row.names=FALSE)
message("Saved per-protein Semantic Similarity table to: ", opt$output)
