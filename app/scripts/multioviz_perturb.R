library(BANN)
library(multioviz)

# Load directories
datadir = "/Users/ashleyconard/Documents/my_projects/multio-viz/example_data/"
outdir = "/Users/ashleyconard/Desktop/multio-viz/results/"

# Load input data
X = as.matrix(read.table(paste(datadir,"X.txt",sep="/")))
y = read.table(paste(datadir,"y.txt", sep="/"), row.names = 1)
y = y[,1]
mask = as.matrix(read.table(paste(datadir,"mask.txt", sep="/")))

#Run BANN
res = BANN(X, mask ,y, centered=FALSE, show_progress = TRUE)
save(res, file = paste(outdir, "res.RData", sep="/"))

# Make between (btw) molecular level map from mask
map_indices <- which(mask != 0, arr.ind = T)
btw_ML_map <- data.frame(matrix(ncol = 2, nrow = 0))
colnames(btw_ML_map) <- c("from", "to")
for(row in 1:nrow(map_indices)) {
    row_name = rownames(mask)[map_indices[row,][1]]
    col_name = colnames(mask)[map_indices[row,][2]]
        btw_ML_map[nrow(btw_ML_map) + 1,] = c(row_name, col_name)
}
write.csv(btw_ML_map, file = paste(outdir, 'btw_ML_map.csv', sep="/"), quote=F, row.names=F)

# Save posterior inclusion probabilities (PIP) scores for all ML1 (molecular level 1)
list_ML1 = data.frame(rownames(mask))
ML1_pips <- cbind("score"=res$SNP_level$pip, "id"=list_ML1)
names(ML1_pips)[2] <- "id"
ML1_pips <- ML1_pips[order(-ML1_pips$score),]
write.csv(ML1_pips, file = paste(outdir, 'ML1_pip.csv', sep="/"), quote=F, row.names=F)

# Save posterior inclusion probabilities (PIP) scores for all ML2 (molecular level 2)
list_ML2 = data.frame(colnames(mask))
ML2_pips <- cbind("score"=res$SNPset_level$pip, "id"=list_ML2)
names(ML2_pips)[2] <- "id"
ML2_pips <- ML2_pips[order(-ML2_pips$score),]
write.csv(ML2_pips, file = paste(outdir, "ML2_pip.csv", sep="/"), quote=F, row.names=F)

# Run platform
runApp("app/")#,outdir)




################
#s_names <- paste("s", 1:dim(mat)[1], sep="")
#g_names <- paste("g", 1:dim(mat)[2], sep="")
#rownames(mat) <- s_names
#colnames(mat) <- g_names

# # Simulate annotation mask (not biological here), where every five SNPs falls into one SNP-set in order
# nSNPs= p # number of SNPs
# nSets= int(p/5) # number of SNP-sets 
# mask=np.zeros(shape=(nSNPs,nSets)) # initialize as a matrix of zeros of size nSNPs by nSets
# #TODO: add gene and CpG names to mask
# for i in range(0,nSets):#iterating over the columns of the annotation matrix, which correspond to SNP-sets
#     for j in range(i*5,(i+1)*5): #iterating over the rows of the annotation matrix, which correspond to SNPs
#         mask[j,i]=1 #Make corresponding 5 SNPs fall into the corresponding SNPsets by turning these values to "1"

# print("The annotation mask has shape:", mask.shape, "with ", mask.shape[0], " SNPs and ", mask.shape[1], 
# " SNP-sets.")
