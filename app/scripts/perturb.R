##' Runs BANNs
##'
##' @param X_input: a matrix of patients by SNPs
##' @param mask_input: a matrix of SNPs by genes
##' @param y_input: a list of phenotypes for each patient
##' @return lst: dataframes for prioritized SNPs/genes and mapping between them
runMethod <- function(X_input, mask_input, y_input) {

  # Load mathemetical model here
  library(BANN)

  y_input <- y_input[, 1]

  res <- BANN(X_input, mask_input, y_input, centered = FALSE, show_progress = TRUE)
  print("BANNs finished running")

  # Make between (btw) molecular level map from mask
  map_indices <- which(unname(mask_input) != 0, arr.ind = T)
  btw_ML_map <- data.frame(matrix(ncol = 2, nrow = 0))
  colnames(btw_ML_map) <- c("from", "to")
  for (row in 1:nrow(map_indices)) {
    row_name <- rownames(mask_input)[map_indices[row, ][1]]
    col_name <- colnames(mask_input)[map_indices[row, ][2]]
    btw_ML_map[nrow(btw_ML_map) + 1, ] <- c(row_name, col_name)
  }

  # Save posterior inclusion probabilities (PIP) scores for all ML1 (molecular level 1)
  SNP_id_list <- as.list(rownames(mask_input))
  num_SNPs <- dim(unname(mask_input))[1]

  SNP_pip_list <- list()
  for (i in 1:num_SNPs) {
    SNP_pip_list <- append(SNP_pip_list, res$SNP_level$pip[[i]])
  }
  lapply(SNP_pip_list, as.numeric)
  ML1_pips <- data.frame(unlist(SNP_id_list), unlist(SNP_pip_list))
  colnames(ML1_pips) <- c("id", "score")

  # Save posterior inclusion probabilities (PIP) scores for all ML2 (molecular level 2)
  gene_id_list <- as.list(colnames(mask_input))
  num_genes <- dim(unname(mask_input))[2]

  gene_pip_list <- list()
  for (i in 1:num_genes) {
    gene_pip_list <- append(gene_pip_list, res$SNPset_level$pip[[i]])
  }
  lapply(gene_pip_list, as.numeric)
  ML2_pips <- data.frame(unlist(gene_id_list), unlist(gene_pip_list))
  colnames(ML2_pips) <- c("id", "score")

  lst <- list()
  lst$ML1 <- ML1_pips
  lst$ML2 <- ML2_pips
  lst$map <- btw_ML_map
  return(lst)
}