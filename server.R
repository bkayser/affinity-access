
source('scheduleDownload.R')
source('transform.R')

library(googleCloudStorageR)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    
    schedule <- reactiveVal(NULL) # Reactive value to store the data
    scheduleKey <- ""
    
    # keep the screen from going grey from timeouts
    keep_alive <- reactiveTimer(intervalMs = 5 * 60 * 1000) # 10 seconds
    observe({
        keep_alive()
        # You can add code here if you want to perform any action
        # when the timer fires.
    })
    
    observeEvent(input$previewSchedule, {
        runPreview(input$scheduleKey)
    })
    
    observeEvent(input$addButton, {
        runPreview(extractGuidFromURL(input$newUrl))
        scheduleKeys <- getLiveScheduleList()
        updateSelectizeInput(session, 'scheduleKey', 
                             choices = scheduleKeys)    
        
        updateTextInput(session, "newUrl", value = "") 
    })
    
    observeEvent(input$clearFilter, {
        updateTextInput(session, "home", value = "")
        updateTextInput(session, "away", value = "")
    })
    output$schedule <- DT::renderDT({
        schedule()
    })
    
    output$downloadSchedule <- downloadHandler(
        filename = function() {
            paste("schedule-", Sys.Date(), ".csv", sep = "")
        },
        contentType = "text/csv",
        content = function(file) {
            runPreview(input$scheduleKey) # Ensure data is available
            write.csv(schedule(), file, row.names = FALSE)
        }
    )
    
    observe({
        if (!is.null(schedule())) {
            shinyjs::enable("downloadSchedule") # Enable if schedule is not NULL
        } else {
            shinyjs::disable("downloadSchedule") # Disable if schedule is NULL
        } 
    })
    
    runPreview <- \(guid) {
        tryCatch({
            if (guid == scheduleKey) return
            scheduleKey <<- guid
            newSchedule <- getStoredVersion(scheduleKey)
            if (is.null(newSchedule)) {
                shinybusy::show_modal_spinner()
                newSchedule <- read_league(str_c("https://oysa.affinitysoccer.com/tour/public/info/accepted_list.asp?tournamentguid=", guid))
                storeVersion(scheduleKey, newSchedule)
                shinybusy::remove_modal_spinner()
            }
            
            filteredSchedule <- 
                if (str_length(input$home) + str_length(input$away) > 0) {
                    filter(newSchedule$schedule,
                           (if (str_length(input$home) > 0) str_detect(Home, coll(input$home, ignore_case=T)) else F) |
                               (if (str_length(input$away) > 0) str_detect(Away, coll(input$away, ignore_case=T)) else F)
                    )
                } else {
                    newSchedule$schedule
                }
                           
            # Replace this with your data generation logic
            schedule(transformSchedule(filteredSchedule)) # Update the reactive value
        }, error = \(e) {
            print(e)
            shinyalert::shinyalert(title="Unexpected Problem",
                                   text=str_c("Unable to preview the schedule with key ",
                                              guid, ":\n", e$message))
        })
    }
    observeEvent(input$aboutButton, {
        showModal(
            modalDialog(
                title="About",
                HTML(markdown::mark(read_file("About.md")))
            )
        )
    })
    
    extractGuidFromURL <- \(url) {
        if (str_detect(url, "^(https://)?oysa.affinitysoccer.com/")) {
            guid <- str_match(url, "[Tt]ournamentguid=([A-G0-9\\-]+)")[2]
        } else if (str_detect(url, "^[A-G0-9\\-]+$")) {
            guid <- url
        } else stop("Invalid league schedule URL or GUID: ", url) 
        guid
    }
    
    transformSchedule <- \(raw) {
        if (input$csvType == "raw")
            return(raw)
        else if (input$csvType == "pm") {
            return(toPlayMetrics(raw))
        } else {
            return(toReftown(raw))
        }
    }
}


