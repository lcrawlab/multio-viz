#install.packages("devtools", repos="http://cran.us.r-project.org") # nolint
library(devtools)
devtools::load_all()
devtools::install()
library(multioviz)
runMultioviz()
