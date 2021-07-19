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

## How to Run App
1. Install R and RStudio
2. Download the "edge.csv" and "nodes.csv" dataframes 
3. Open the "visNet_Rshiny_script" file located in this repo in RStudio
4. Highlight lines 1-2 and click "Run selected lines" in the RStudio Code menu
5. Repeat Step 4 for lines 4-19
5. Repeat Step 4 for line 21

## Usage
For our interactive app, the nodes represent genes in the network and the edges represent interactions between genes. The size of the gene nodes are weighted by their posterior inclusion propabilities obtained from BIOGRINN. To use, click on a node to highlight the node and all edges connected to the node. Hover over a node to show the gene number. 

 


## This develop branch is where all code is pushed. After Ashley performs a code review, it can be merged into the master branch. 

