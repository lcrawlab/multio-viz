# Use base rocker image for shiny server and R
FROM rocker/shiny:4.0.5

# Make shiny server directory
RUN mkdir -p /srv/shiny-server

# Get system libraries
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libel-parser-perl \

# Install R packages
RUN R -e 'install.packages(c("shiny","visNetwork","shinydashboard", "ggplot2"))'

# Copy contents of app directory
COPY ./app/app.R /srv/shiny-server/
COPY ./app/scripts /srv/shiny-server/
COPY ./app/www /srv/shiny-server/
COPY ./data 

# Run app
CMD ["/usr/bin/shiny-server"]
