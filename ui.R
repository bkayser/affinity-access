library(bslib)

selections <- read.csv("URLS.csv")
LEAGUES <- setNames(selections$url, selections$title)

ui <- \() fluidPage(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
    titlePanel("Affinity CSV Schedule Download", "Schedule Utility"),
    sidebarLayout(
        sidebarPanel(width=4,
            selectizeInput(
                "scUrl",
                "Select a known schedule:",
                choices = LEAGUES,
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
