# Use base rocker image for shiny server and R
FROM rocker/shiny:4.0.5

# Make shiny server directory
RUN mkdir -p /srv/shiny-server

# Get system libraries
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml-parser-perl
#    libel-parser-perl

# Install R packages
RUN R -e 'install.packages("devtools", repos="http://cran.us.r-project.org", dependencies = TRUE)'
RUN R -e 'install.packages("shiny", version = "1.7.1", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("visNetwork", version = "2.1.0", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("igraph", version = "1.3.5", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("dplyr", version = "1.0.2", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("shinyBS", version = "0.61", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("shinythemes", version = "1.2.0", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("shinydashboard", version = "0.7.2", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("shinydashboardPlus", version = "2.0.3", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("shinyWidgets", version = "0.7.4", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("shinyjs", version = "2.1.0", repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("BANN")'

# Copy contents of app directory

COPY ./app /srv/shiny-server/
COPY ./BANNs /srv/shiny-server/
COPY ./example_data /srv/shiny-server/
COPY ./multioviz /srv/shiny-server/
COPY ./runMultioviz.R /srv/shiny-server/
COPY ./setupMultioviz.sh /srv/shiny-server/
COPY ./README.md /srv/shiny-server/
COPY ./R_PACKAGE_DIRECTIONS /srv/shiny-server/
COPY ./demo.R /srv/shiny-server/
COPY ./load_multioviz.R /srv/shiny-server/
COPY ./load_packages.R /srv/shiny-server/

COPY ./multio-viz.Rproj /srv/shiny-server/
COPY ./multio-viz_res /srv/shiny-server/
COPY ./own_computational_method.R /srv/shiny-server/

# Run app
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]