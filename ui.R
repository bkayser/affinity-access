library(bslib)
library(tidyverse)
source("cloud_storage.R")

gcs_auth(json_file="gcs_auth.json", email="pennybot@gmail.com")
gcs_global_bucket("production.affinityaccess.live")

ui <- \() fluidPage(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
    titlePanel("Affinity CSV Schedule Download", "Schedule Utility"),
    tags$link(rel="preconnect", href="https://fonts.googleapis.com"),
    tags$meta(name="description", content="Welcome to AffinityAccess.live!"),
        
    sidebarLayout(
        sidebarPanel(width=4,
            selectizeInput(
                "scheduleKey",
                "Select a known schedule:",
                choices = getLiveScheduleList(),
                options = list(create = TRUE, # Makes it editable
                               maxItems=1,
                               placeholder="Choose a known schedule")
            ),
            radioButtons(
                "csvType",
                "CSV Format:",
                choices = list("Raw CSV"="raw", "PlayMetrics Upload Ready CSV"="pm", "Reftown Upload Ready CSV"="reftown")
            ),
            tags$hr(class="separator"),

            textInput("newUrl", 
                      label="Or enter the URL for a schedule on the affinity site to add it to the list:",
                      placeholder="https://oysa.affinitysoccer.com/tour/public/info/accepted_list.asp?tournamentguid={GUID}"),
            actionButton("addButton", "Add schedule to list"),
            tags$hr(class="separator"),
            
            actionButton("aboutButton", "About"),
        ),
        
        mainPanel(
            class="main",
            width=8,
            card(class='filter-controls',
                 card_header("Club or Team Filters"),
                 layout_column_wrap(
                     textInput("home", "Home:"),
                     textInput("away", "Away:")
                 )
            ),
            layout_column_wrap(
                class="buttons",
                width="140px",
                fixed_width = TRUE,
                actionButton("previewSchedule",  "Preview", class="button"),
                actionButton("clearFilter",  "Clear Filter", class="button"),
                shinyjs::disabled(downloadButton("downloadSchedule", "Download", class="button"))
                
            ),
            wellPanel(
                class="mainpanel",
                caption="Retrieving Schedule Information",
                DT::DTOutput("schedule")
            )
        )
    )
)
