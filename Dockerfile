# Base R Shiny image
FROM rocker/shiny-verse

# Set the working directory
WORKDIR /home/shiny

# Install R dependencies
RUN R -e "install.packages(c('DT', 'shinycssloaders', 'bslib', 'shinyjs', 'shinybusy', 'XML', 'rvest', 'httr'))"
RUN R -e "install.packages(c('shinyalert'))"
RUN R -e "install.packages('googleCloudStorageR')"

# Copy the Shiny app code
COPY *.R URLS.csv .
COPY www/ www

# Expose the application port
EXPOSE 8080

# Run the R Shiny app
# CMD Rscript ./app.R
CMD ["R", "-e", "shiny::runApp('/home/shiny', port=8080, host='0.0.0.0')"]