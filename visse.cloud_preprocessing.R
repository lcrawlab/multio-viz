rm(list = ls())
library(BANN)

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

# Rank genes by score
sorted_gene_matrix <- as.matrix(gene_level_pip[order(gene_level_pip[, 1], decreasing = TRUE), ])
genes_ranked <- as.matrix(1:nrow(sorted_gene_matrix))
rownames(genes_ranked) <- rownames(sorted_gene_matrix) 
colnames(genes_ranked) <- "statistic"

# Filter out rows where the gene column contains 'Intergenic'
genes_ranked <- genes_ranked[!grepl("Intergenic", genes_ranked$gene), ]

# Convert the 'statistic' column to numeric and rename it to 'pval'
genes_ranked$statistic <- as.numeric(sorted_gene_matrix$statistic)

# Connect to the Ensembl database
ensembl <- useMart("ensembl", dataset = "hsapiens_gene_ensembl")

# Function to convert mouse gene names to human gene names
convert_mouse_to_human <- function(mouse_gene_names) {
  mouse_to_human <- getLDS(attributes = c("mgi_symbol", "hgnc_symbol"), filters = "mgi_symbol", values = mouse_gene_names, mart = ensembl)
  mouse_to_human <- na.omit(mouse_to_human)  # Remove NA values
  return(mouse_to_human)
}

# Convert mouse gene names to human gene names
mouse_to_human <- convert_mouse_to_human(rownames(genes_ranked))

# Update row names of the matrix with human gene names
human_gene_names <- mouse_to_human$hgnc_symbol
rownames(genes_ranked) <- human_gene_names

# Write to file to then copy and paste into visse.cloud GSEA
write.table(genes_ranked, "genes_ranked_BANNs.txt", sep = "\t", row.names = TRUE, col.names = FALSE)

