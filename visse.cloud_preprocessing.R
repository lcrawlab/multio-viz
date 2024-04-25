krm(list = ls())
library(BANN)
library(dplyr)

# Read in mouse data
X = as.matrix(read.table("example_data/X_CD8.txt"))
y = read.table("example_data/y_CD8.txt")
y = y[,1]
mask = as.matrix(read.table("example_data/mask.txt"))

# Manual Perturbation
col_number <- which(colnames(mask) == "Shisa9")
mask <- mask[, -col_number]

# Run BANN
res = BANN(X, mask ,y, centered=FALSE, show_progress = TRUE)

# Access posterior inclusion probability for Gene layer
gene_level_pip <- as.matrix(res$SNPset_level$pip)

# Rank genes by PIP score and use rankings as statistic column
sorted_gene_matrix <- as.matrix(gene_level_pip[order(gene_level_pip[, 1], decreasing = TRUE), ])
genes_ranked <- as.matrix(1:nrow(sorted_gene_matrix))
rownames(genes_ranked) <- rownames(sorted_gene_matrix) 
colnames(genes_ranked) <- "statistic"

# Filter out rows where the gene column contains 'Intergenic'
genes_ranked <- genes_ranked[!grepl("Intergenic", rownames(genes_ranked)), , drop = FALSE]

# Convert the 'statistic' column to numeric
genes_ranked$statistic <- as.numeric(sorted_gene_matrix$statistic)

# Connect to the MGI database
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
human_gene_names <- convert_mouse_to_human(rownames(genes_ranked))
genes_ranked <- genes_ranked[!grepl("None", rownames(genes_ranked)), , drop = FALSE]

# Update row names of the matrix with human gene names
rownames(genes_ranked) <- human_gene_names

# Write to file to then copy and paste into visse.cloud GSEA
write.table(genes_ranked, "gene_ranks_clean.txt", sep = "\t", row.names = TRUE, col.names = FALSE)

