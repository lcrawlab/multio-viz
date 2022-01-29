FROM rocker/r-base:latest ## * if you change this to shiny base image
RUN mkdir -p /srv/shiny-server
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
<<<<<<< HEAD
RUN R -e "install.packages('visNetwork', repos='http://cran.rstudio.com/')"
RUN install.r shiny
COPY app /srv/shiny-server
COPY data /srv/shiny-server
#EXPOSE 3838
#RUN sudo chown -R shiny:shiny /srv/shiny-server ## *
CMD ["R", "-e", "shiny::runApp("/srv/shiny-server/app/Rshiny.R")"]
=======
    && rm -rf /var/lib/apt/lists/*
    
RUN install.r shiny
COPY Rshiny.R /srv/shiny-server
COPY scripts /srv/shiny-server
COPY colorbar.png /srv/shiny-server

EXPOSE 3838
RUN sudo chown -R shiny:shiny /srv/shiny-server
CMD ["R", "-e", "shiny::runApp('/home/app')"]
>>>>>>> ef282cffedb897e883493d876082425a042b9300
CMD ["/usr/bin/shiny-server.sh"]
#CMD [runApp("/srv/shiny-server/app/Rshiny.R")]

