# Multi-omics Gene Regulatory Network Interactive Visualization
### Ashley Conard, Helen Xie, Lorin Crawford

## About the Project
The goal of our project is to build an interactive gene regulatory network application to visualize the results from **Bayesian Inference of Omics for Genomic Regulation Interpretation from Neural Networks (BIOGRINN)**. The network uses CpG methylation and RNA-seq data to determine the degree to which methylation and expression of certain genes contribute to the expression of a cancer biomarker. Identifying and understanding these multi-omic interactions provides insight into how aberrant gene expression leads to cancer phenotypes and may lead to the discovery of new biomarkers. In clinical settings, using GRNs to examine a patient’s cancer profile allows for the identification of pathway target therapies in personalized medicine. 

## Built With
- R version 4.1.0
- RStudio
- R Shiny package
- visNetwork package
- BIOGRINN data

## Generating Network
1. Open RStudio
2. cd 'multio-viz'
3. Run 'multio-viz/Rshiny.R'

## Usage
For our interactive app, the nodes represent genes in the network and the edges represent interactions between genes. The size of the gene nodes are weighted by their posterior inclusion propabilities obtained from BIOGRINN. To use, hover over a node to highlight the node and all edges connected to the node, and to view a popup of the gene name. Users can select by gene id and by omics type with dropdown menus. With the edit button, users can add notes, edges, and notes after the app is created. 

 


## This develop branch is where all code is pushed. After Ashley performs a code review, it can be merged into the master branch. 

