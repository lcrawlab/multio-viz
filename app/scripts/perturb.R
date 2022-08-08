
runModel <- function(X, y, mask) {

  # Load mathemetical model here
  library(BANN)
  print(mask)
  #Run model here
  print('here0')
  print(mask)
  mask_input <- mask
  print(mask_input)
  colnames(mask_input) = NULL
  print(mask_input)
  print(is.null(mask_input))

  X_input = as.matrix(unname(X))

  print('mask dim')
  #print(dim(mask_input))
  print('X dim')
  #print(dim(X_input))

  res = BANN(X_input, mask_input, y, centered=FALSE, show_progress = TRUE)
  #save(res, file = paste(outdir, "res.RData", sep="/"))
  print('here 1')
  # Make between (btw) molecular level map from mask
  map_indices <- which(mask != 0, arr.ind = T)
  btw_ML_map <- data.frame(matrix(ncol = 2, nrow = 0))
  colnames(btw_ML_map) <- c("from", "to")
  for(row in 1:nrow(map_indices)) {
      row_name = rownames(mask)[map_indices[row,][1]]
      col_name = colnames(mask)[map_indices[row,][2]]
          btw_ML_map[nrow(btw_ML_map) + 1,] = c(row_name, col_name)
  }
  print('here 2')
  #write.csv(btw_ML_map, file = paste(outdir, 'btw_ML_map.csv', sep="/"), quote=F, row.names=F)

  # Save posterior inclusion probabilities (PIP) scores for all ML1 (molecular level 1)
  list_ML1 = data.frame(rownames(mask))
  num_SNPs = dim(mask_input)[1]

  SNP_pip_list = list()
  for(i in 1:num_SNPs){
    SNP_pip_list.append(res$SNP_level$pip[[i]])
  }
  SNP_pip_list = as.data.frame(SNP_pip_list)
  
  ML1_pips <- cbind("score"=SNP_pip_list, "id"=list_ML1)
  names(ML1_pips)[2] <- "id"
  ML1_pips <- ML1_pips[order(-ML1_pips$score),]
  #write.csv(ML1_pips, file = paste(outdir, 'ML1_pip.csv', sep="/"), quote=F, row.names=F)
  print('here 3')
  # Save posterior inclusion probabilities (PIP) scores for all ML2 (molecular level 2)
  list_ML2 = data.frame(colnames(mask))
  num_genes = dim(mask_input)[2]

  gene_pip_list = list()
  for(i in 1:num_genes){
    gene_pip_list.append(res$SNPset_level$pip[[i]])
  }
  gene_pip_list = as.data.frame(gene_pip_list)

  ML2_pips <- cbind("score"=gene_pip_list, "id"=list_ML2)
  names(ML2_pips)[2] <- "id"
  ML2_pips <- ML2_pips[order(-ML2_pips$score),]
  #write.csv(ML2_pips, file = paste(outdir, "ML2_pip.csv", sep="/"), quote=F, row.names=F)

  return(list[ML1_pips, ML2_pips, btw_ML_map])
}