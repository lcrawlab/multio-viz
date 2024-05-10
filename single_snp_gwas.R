rm(list = ls())
library(BANN)
library(dplyr)

# Read in mouse data
X = as.matrix(read.table("example_data/X_CD8.txt"))
y = read.table("example_data/y_CD8.txt")
y = y[,1]
mask = as.matrix(read.table("example_data/mask.txt"))

# col_number <- which(colnames(mask) == "Kit")
# mask <- mask[, -col_number]

# perform_gene_gwas <- function(genotype, phenotype, mask_matrix) {
#   gene_names <- colnames(mask_matrix)
#   gene_p_values <- numeric(length(gene_names))
  
#   for (i in 1:length(gene_names)) {
#     snps_in_gene <- which(mask_matrix[, i] == 1)
#     if (length(snps_in_gene) == 0) {
#       gene_p_values[i] <- NA
#     } else {
#       model <- lm(phenotype ~ genotype[, snps_in_gene])
#       p_value <- summary(model)$coefficients[2, 4]  # Extract p-value directly from summary
#       gene_p_values[i] <- p_value
#     }
#   }
  
#   gene_results <- data.frame(Gene = gene_names, p.value = gene_p_values, stringsAsFactors = FALSE)
#   return(gene_results)
# }

perform_gene_gwas <- function(genotype, phenotype, mask_matrix) {
  gene_names <- colnames(mask_matrix)
  gene_p_values <- numeric(length(gene_names))
  
  for (i in 1:length(gene_names)) {
    snps_in_gene <- which(mask_matrix[, i] == 1)
    if (length(snps_in_gene) == 0) {
      gene_p_values[i] <- NA
    } else {
      min_p_value <- Inf
      for (j in snps_in_gene) {
        model <- lm(phenotype ~ genotype[, j])
        p_value <- summary(model)$coefficients[2, 4]
        if (p_value < min_p_value) {
          min_p_value <- p_value
        }
      }
      gene_p_values[i] <- min_p_value
    }
  }
  
  gene_results <- data.frame(Gene = gene_names, p.value = gene_p_values, stringsAsFactors = FALSE)
  return(gene_results)
}

gene_gwas_results <- perform_gene_gwas(X, y, mask)

mouse_human_genes = read.csv("http://www.informatics.jax.org/downloads/reports/HOM_MouseHumanSequence.rpt",sep="\t")

# Function to convert mouse gene names to human gene names
convert_mouse_to_human <- function(mouse_gene_names) {
  output <- c()
  for (gene in mouse_gene_names) {
    class_key <- (mouse_human_genes %>% 
                   filter(Symbol == gene & Common.Organism.Name == "mouse, laboratory"))[['DB.Class.Key']]
    if (!identical(class_key, integer(0))) {
      human_genes <- (mouse_human_genes %>% 
                        filter(DB.Class.Key == class_key & Common.Organism.Name == "human"))[,"Symbol"]
      if (length(human_genes) == 0) {
        output <- append(output, "None")
      } else {
          output <- append(output, human_genes[1])
      }
    } else {
      output <- append(output, "None")
    }
  }
  return(output)
}

# Convert mouse gene names to human gene names
human_gene_names <- convert_mouse_to_human(gene_gwas_results$Gene)
gene_gwas_results$Gene <- human_gene_names
gene_gwas_results <- gene_gwas_results[gene_gwas_results$Gene != "None", ]

write.table(gene_gwas_results, "single_snp_gwas_pvals.txt", sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
