FROM rocker/r-base:latest
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    && rm -rf /var/lib/apt/lists/*
    
RUN install.r shiny
COPY Rshiny.R /srv/shiny-server
COPY scripts /srv/shiny-server
COPY colorbar.png /srv/shiny-server

EXPOSE 3838
RUN sudo chown -R shiny:shiny /srv/shiny-server
CMD ["R", "-e", "shiny::runApp('/home/app')"]
CMD ["/usr/bin/shiny-server.sh"]

