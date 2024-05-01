<img
  src="./app/www/logo.png"
  alt="multioviz"
  title="Logo"
  style="display: inline-block; margin: 0 auto; max-width: 300px">

### Multioviz: a platform for the interactive assessment of gene regulatory networks
##### Authors: Helen Xie, Lorin Crawford, Ashley Mae Conard

## Outline
- [Introduction](#introduction)
- [Quickstart](#quickstart-3-usages)
- [Dependencies](#dependencies)
- [Ways to run Multioviz through the command line](#ways-to-run-multioviz-through-the-command-line)
- [Input requirements](#input-requirements)
- [Visualize enriched molecular features as a GRN](#a-visualize-ranked-molecular-features-as-a-grn)
- [Generate a perturbable GRN to test hypotheses *in-silico*](#b-generate-a-perturbable-grn-to-test-hypotheses-in-silico)
- [Integrate computational method](#c-integrate-feature-selection-and-prioritization-method)

## Introduction
Multioviz is a free, user-friendly, interactive platform that facilitates *in-silico* hypothesis testing by combining computational inference of gene regulatory network (GRN) architectures with interactive visualization and perturbation. To generate a perturbable GRN, users can input either individual or population level multiomics data in addition to corresponding phenotypic data. Users can also directly visualize GRNs by directly inputting prioritized lists of molecular features along with mapping data between and within molecular levels the features belong to. We provide an R package version of Multioviz that allows programmers to integrate any computational method that performs feature selection and prioritization, generalizing our platform to accept and model different genomic datasets at multiple molecular scales. Visit Multioviz at https://multioviz.ccv.brown.edu/.

<img
  src="./app/readme/figure1.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 2500px">

## Quickstart: 3 usages
Users can (1) visualize significant molecular variable as GRNs (see steps [here](https://github.com/lcrawlab/multio-viz/blob/main/README.md#a-visualize-ranked-molecular-features-as-a-grn)) and (2) perturb GRNs for *in silico* hypothesis testing (see steps [here](https://github.com/lcrawlab/multio-viz/blob/main/README.md#b-generate-a-perturbable-grn-to-test-hypotheses-in-silico)). The user can also (3) integrate their own computational method that performs feature selection and perturbation through the multioviz R package (see steps [here](https://github.com/lcrawlab/multio-viz/blob/main/README.md#c-integrate-feature-selection-and-prioritization-method)).

1. For (1), to quickly visualize a GRN, press "Load Demo Files" and press "RUN" to see the GRN!
   - To load your own data, under the "Visualize" drop down (side bar), upload the [required inputs](#a-visualize), set network preferences, and click "RUN" to visualize the user's data. See the [visualization instructions](#a-visualize-ranked-molecular-features-as-a-grn) for a detailed walk-through. 
2. For (2), to quickly perturb a GRN, press "Load Demo Files" and press "RUN" to see the GRN, followed by clicking any node, then clicking "Edit" to "Delete" or "Edit" the node. Then click "RERUN".
   - To load your own data, under the "Perturb" drown down (side bar), upload the [required inputs](#b-perturb), and click "RUN" to generate the network. For a detailed walk through on how to perturb and rerun the user's network, visit the [perturbation](#b-generate-a-perturbable-grn-to-test-hypotheses-in-silico) section.
3. For (3), once the multioviz package is installed, open a new R session (```R```) and load the package (```library multioviz```). Run ```runMultioviz()``` with no arguments to generate a demo network, and with the [required arguments](#c-integrate-computational-method) to generate a network using the user's own method. Visit the [method integration](#c-integrate-feature-selection-and-prioritization-method) section for more detailed instructions.

**Please note that there is a maximum file size limit of _32MB_ for file uploads on this platform. Files exceeding this limit will cause an error, and not be accepted. If you encounter any issues related to this limit, please consider ways to reduce your file size, or reach out for assistance.**

## Dependencies
- R (>= 4.1.2)
- BANN (>= 0.1.0)
- shiny (>= 1.7.1)
- visNetwork (>= 2.1.0)
- igraph (>= 1.3.5)
- dplyr (>= 1.0.2)
- shinyBS (>= 0.61)
- shinythemes (>= 1.2.0)
- shinydashboard (>= 0.7.2)
- shinydashboardPlus (>= 2.0.3)
- shinyWidgets (>= 0.7.4)
- shinyjs (>= 2.1.0)
- shinyalert (>= 3.0.0)
- data.table (>= 1.14.6)

## Ways to run Multioviz through the command-line
### Docker image
1. Pull docker image ```docker pull ashleymaeconard/multioviz```
2. Run docker image ```docker run -p 3838:3838 multioviz```
### Clone repo
1. Clone multio-viz repository ```git clone git@github.com:lcrawlab/multio-viz.git```
2. Setup dependencies ```sh setupMultioviz.sh```
3. Within multio-viz directory, run ```Rscript runMultioviz.R```
### Install R package (for method integration)
1. Clone multio-viz repository ```git clone git@github.com:lcrawlab/multio-viz.git```
2. Within multio-viz directory, run ```R CMD INSTALL multioviz_0.0.0.9000.tar.gz```
3. In R session, load package ```library multioviz``` to use the [runMultioviz()](#runmultioviz-function-tutorial) function 

## Input Requirements
### A. Visualize
- Molecular Level 1 (ML1): a dataframe with columns for the 'id' and 'score' of each variable in molecular level 1
- Molecular Level 2 (ML2): a dataframe with columns for the 'id' and 'score' of each variable in molecular level 2
- Map: a dataframe with 'from' and 'to' columns to map features in ML1 to features in ML2 

<img
  src="./app/www/example_data_viz.png"
  alt="Alt text"
  title="runModel example"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">

### B. Perturb
- X: a N x J dimensional matrix where N is the number of patient samples and J is the size of the set of molecular features for molecular level one (no row/column names)
- y: a N-dimensional matrix of quantitative traits for a sample of patients (no row/column names)
- mask: a J x G matrix of pre-defined annotations where J is the number of molecular features for molecular level 1 and G is the number of molecular features for molecular level 2 (row/column names optional)

<img
  src="./app/www/example_data_perturb.png"
  alt="Alt text"
  title="Model inputs"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">

### C. Integrate computational method
- Computational method performs feature selection and prioritization
- The script with your method should call ```runModel()``` function that
    - has parameters for required inputs (see B. Perturb figure depicting X, y, mask) (# step 1)
    - runs the user's method (# step 2)
    - returns ML1, ML2, and Map (see B. Perturb figure depicting molecular level 1 (SNPs) (ML1), molecular level 2 (genes) (ML2), and mapping between molecular levels) (# step 3)

As an example, the script could look something like, where we run BANNs as our example computational method:
```
runModel <- function(X_input, y_input, mask_input) { # step 1

  # run your computational method
  res = BANN(X_input, mask_input, y_input, centered=FALSE, show_progress = TRUE) # step 2

  # convert method output to ML1, ML2, and map 

  lst = list()
  lst$ML1 = ML1_pips
  lst$ML2 = ML2_pips # step 3
  lst$map = btw_ML_map
  return(lst)
}
```

## A. Visualize ranked molecular features as a GRN
To facilitate *in silico* hypothesis generation, Multioviz allows users to visualize ranked lists and maps of enriched molecular features for a given phenotypic state as GRNs.

<img
  src="./app/readme/fig2.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 2500px">

### Steps to run
1. Click on the visualization drop down (side bar)
<img
  src="./app/readme/viz1.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
2. Input files for ML1, ML2, and maps between molecular levels
<img
  src="./app/readme/viz2.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
3. Select degree of mapping within molecular levels
<img
  src="./app/readme/viz3.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
4. Threshold features in each molecular level by statistical significance
<img
  src="./app/readme/viz4.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
5. Set GRN layout
<img
  src="./app/readme/viz5.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
6. Click "RUN" to visualize GRN
<img
  src="./app/readme/viz6.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">

## B. Generate a perturbable GRN to test hypotheses *in silico*
To faciliate *in silico* hypothesis testing, Multioviz allows users to manually delete nodes and edges, and then rerun the ranking model to generate a new network with different significant molecular features. 

<img
  src="./app/readme/fig3.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 2500px">

### Steps to run
1. Click on the perturbation drop down the left panel
<img
  src="./app/readme/p1.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
2. Input X, y, and mask files for perturbation
<img
  src="./app/readme/p2.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
3. Select degree of mapping within molecular levels
<img
  src="./app/readme/p3.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
4. Threshold features in each molecular level by statistical significance
<img
  src="./app/readme/p4.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
5. Set GRN layout
<img
  src="./app/readme/p5.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
6. Click "RUN" to generate GRN
<img
  src="./app/readme/p6.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
7. Select features(s) to delete and click "Edit"
<img
  src="./app/readme/p7.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
8. Click "Delete selected" to manually remove node
<img
  src="./app/readme/p8.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
9. Click "RERUN" to generate new GRN
<img
  src="./app/readme/p9.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">
 10. Explore perturbed GRN
<img
  src="./app/readme/p10.png"
  alt="Alt text"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">

## C. Integrate feature selection and prioritization method
The multioviz package contains a runMultioviz() function that allows users to connect the perturbation and visualization capabilities of the Multioviz platform with their computational method that performs feature selection and prioritization. The function accepts 3 parameters ```runMultioviz(X, y, mask)``` to run user data with BANNs, and 4 parameters ```runMultioviz(X, y, mask, userScript)``` to run user data with the user's own feature selection and prioritization method.

Once the multioviz package has been installed, run ```Rscript demo.R``` in the command line for a demo.

<img
  src="./app/readme/pkgUI.png"
  alt="Alt text"
  title="runModel() example"
  style="display: inline-block; margin: 0 auto; max-width: 1000px">

### runMultioviz() function tutorial
1. Write script with a ```runModel()``` function
2. Save X, y, and mask files as .rda files
3. Load in X, y, and mask files
```
> load('path to X.rda file')
> load('path to y.rda file')
> load('path to mask.rda file')
```
4. Save path to the user script as a variable
```
> userScript = "'path to user script'"
```
5. Run app with runMultioviz(X, y, mask, userScript) function
```
> runMultioviz(X.rda, y.rda, mask.rda, userScript)
```
6. Follow perturbation steps from the [section above](#b-generate-a-perturbable-grn-to-test-hypotheses-in-silico)

 ## RELEVANT CITATIONS

H. Xie, L. Crawford, and A.M. Conard. Multioviz: an interactive platform for in silico perturbation and interrogation of gene regulatory networks. _bioRxiv_. 2023.10.10.561790.

## QUESTIONS AND FEEDBACK
For questions or concerns with the Multioviz platform or software, please contact Ashley Mae Conard, Lorin Crawford, or [Helen Xie](mailto:helen_xie@brown.edu).

We welcome and appreciate any feedback you may have with our software and/or instructions.










