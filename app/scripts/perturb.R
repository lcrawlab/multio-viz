
runModel <- function(X, mask, y) {

  # Load mathemetical model here
  library(BANN)

  X_input = unname(X)
  mask_input = unname(mask)
  y_input = y[,1]

  res = BANN(X_input, mask_input, y_input, centered=FALSE, show_progress = TRUE)
  #save(res, file = paste(outdir, "res.RData", sep="/"))

  # Make between (btw) molecular level map from mask
  map_indices <- which(mask_input != 0, arr.ind = T)
  btw_ML_map <- data.frame(matrix(ncol = 2, nrow = 0))
  colnames(btw_ML_map) <- c("from", "to")
  for(row in 1:nrow(map_indices)) {
      row_name = rownames(mask)[map_indices[row,][1]]
      col_name = colnames(mask)[map_indices[row,][2]]
          btw_ML_map[nrow(btw_ML_map) + 1,] = c(row_name, col_name)
  }
  #write.csv(btw_ML_map, file = paste(outdir, 'btw_ML_map.csv', sep="/"), quote=F, row.names=F)
  # Save posterior inclusion probabilities (PIP) scores for all ML1 (molecular level 1)
  SNP_id_list = list(rownames(mask))
  num_SNPs = dim(mask_input)[1]

  SNP_pip_list = list()
  for(i in 1:num_SNPs){
    SNP_pip_list = append(SNP_pip_list, res$SNP_level$pip[[i]])
  }
  lapply(SNP_pip_list, as.numeric)
  ML1_pips = data.frame(unlist(SNP_id_list), unlist(SNP_pip_list))
  colnames(ML1_pips) = c('id', 'score')
  #write.csv(ML1_pips, file = paste(outdir, 'ML1_pip.csv', sep="/"), quote=F, row.names=F)

  # Save posterior inclusion probabilities (PIP) scores for all ML2 (molecular level 2)
  gene_id_list = list(colnames(mask))
  num_genes = dim(mask_input)[2]

  gene_pip_list = list()
  for(i in 1:num_genes){
    gene_pip_list = append(gene_pip_list, res$SNPset_level$pip[[i]])
  }
  lapply(gene_pip_list, as.numeric)
  ML2_pips = data.frame(unlist(gene_id_list), unlist(gene_pip_list))
  colnames(ML2_pips) = c('id', 'score')
  #write.csv(ML2_pips, file = paste(outdir, "ML2_pip.csv", sep="/"), quote=F, row.names=F)
  
  lst = list()
  lst$ML1 = ML1_pips
  lst$ML2 = ML2_pips
  lst$map = btw_ML_map
  #lst = c(ML1_pips, ML2_pips, btw_ML_map)
  return(lst)
}