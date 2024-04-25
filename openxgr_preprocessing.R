rm(list = ls())
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
colnames(gene_level_pip) <- "statistic"

# Filter out rows where the gene column contains 'Intergenic'
gene_level_pip <- gene_level_pip[!grepl("Intergenic", rownames(gene_level_pip)), , drop = FALSE]

# Convert the 'statistic' column from PIP to p-values
gene_level_pip[, 1] <- 1 - gene_level_pip[, 1]

# Sort the data frame by the 'statistic' column
gene_level_pip <- gene_level_pip[order(gene_level_pip$statistic), ]

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
human_gene_names <- convert_mouse_to_human(rownames(gene_level_pip))
gene_level_pip <- gene_level_pip[!grepl("None", rownames(gene_level_pip)), , drop = FALSE]

# Write to file - copy and paste file contents in OpenXGR SAgene
write.table(as.matrix(gene_level_pip), "gene_pvals_clean.txt", sep = "\t", row.names = TRUE, col.names = FALSE)

