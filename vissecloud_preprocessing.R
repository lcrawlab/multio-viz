rm(list = ls())
library(BANN)
library(biomaRt)

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
colnames(gene_level_pip) <- "statistic"

# Filter out rows where the gene column contains 'Intergenic'
gene_level_pip <- gene_level_pip[!grepl("Intergenic", gene_level_pip$gene), ]

# Convert the 'statistic' column to numeric and rename it to 'pval'
gene_level_pip$statistic <- as.numeric(gene_level_pip$statistic)

# Sort the data frame by the 'statistic' column
gene_level_pip <- gene_level_pip[order(gene_level_pip$statistic), ]

# Connect to the Ensembl database
ensembl <- useMart("ensembl", dataset = "hsapiens_gene_ensembl")

# Function to convert mouse gene names to human gene names
convert_mouse_to_human <- function(mouse_gene_names) {
  mouse_to_human <- getLDS(attributes = c("mgi_symbol", "hgnc_symbol"), filters = "mgi_symbol", values = mouse_gene_names, mart = ensembl)
  mouse_to_human <- na.omit(mouse_to_human)  # Remove NA values
  return(mouse_to_human)
}

# Convert mouse gene names to human gene names
mouse_to_human <- convert_mouse_to_human(rownames(gene_level_pip))

# Update row names of the matrix with human gene names
human_gene_names <- mouse_to_human$hgnc_symbol
rownames(gene_level_pip) <- human_gene_names

# Write to file - copy and paste file contents in visse.cloud Gene Set Enrichment Analysis tool
write.table(as.matrix(gene_level_pip), "gene_pvals_BANNs.txt", sep = "\t", row.names = TRUE, col.names = FALSE)

