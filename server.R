
source('scheduleDownload.R')
source('transform.R')
library(googleCloudStorageR)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    
    gcs_auth("gcs_auth.json", email="pennybot@gmail.com")
    gcs_global_bucket("production.affinityaccess.live")
    cache <- cache('schedules')

    schedule <- reactiveVal(NULL) # Reactive value to store the data
    scheduleKey <- ""
    
    observeEvent(input$previewSchedule, {
        runPreview()
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
            runPreview() # Ensure data is available
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
    
    runPreview <- \() {
        tryCatch({
            if (isTruthy(input$newUrl)) {
                guid <- extractGuidFromURL(input$newUrl)
            } else {
                guid <- extractGuidFromURL(input$scUrl)
            }
            newKey <- str_c(guid, "+", Sys.Date())
            if (newKey == scheduleKey) return
            scheduleKey <- newKey
            newSchedule <- cache$get(scheduleKey)
            if (is.null(newSchedule)) {
                shinybusy::show_modal_spinner()
                newSchedule <- read_league(str_c("https://oysa.affinitysoccer.com/tour/public/info/accepted_list.asp?tournamentguid=", guid))
                cache$put(scheduleKey, newSchedule)
                shinybusy::remove_modal_spinner()
            }
            # Save a new selection
            updateURLs(newSchedule$title, guid)
            if (isTruthy(input$newUrl)) {
                updateTextInput(session, "newUrl", value = "") 
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
                                   text=str_c("Unable to preview the schedule at ",
                                              input$scUrl, ":\n", e$message))
        })
    }
    observeEvent(input$aboutButton, {
        showModal(modalDialog(
            title="About",
            tags$p("This utility allows you to download a CSV file from a live schedule on the SportsConnect site."),
            tags$h4("How to Use AffinityAccess.live"),
            tags$p("There is a selector for known schedules on the OYSA Affinity site.  If your schedule
                   does not appear in the list, try entering the URL provided by the league and hit the add 
                   button.  Once added, the schedule should appear in the drop down menu until the application
                   is updated on the server."),
            tags$p("After selecting the schedule, you have a choice of several different download formats to choose from for preview and download:"),
            tags$ul(
                tags$li(em("Raw"), " - a generic format corresponding to the affinity schedule tables."),
                tags$li(em("PlayMetrics Upload Ready"), " - a format with columns mapped to columns known by PlayMetrics on schedule import. 
                   It will likely be necessary to map field names and team names during the import."),
                tags$li(em("Reftown Upload Ready"), " - a format suitable for upload to the referee assigning platform ",
                   tags$a(link="https://reftown.com", "RefTown.com."))
            ),
            p("Hit the Preview button to browse the schedule or the Download button to download the CSV. The first time a schedule downloads for the day there will be a 10-20 second 
              delay while the server is scanning pages on the affinity site."),
            p("Enter any part of the team or club name to select only the games with that name in the Home or Away columns.  This affects the data that will be downloaded."),
            p("Use the search button to search all fields in the schedule.  Note that this will not change what is in the downloaded file."),
            tags$h4("Caveats"),
            tags$ul(
                tags$li("AffinityAccess.live is currently beta testing.  Please report any issues to ", a("href"="mailto:admin@affinityaccess.live", "admin@affinityaccess.live.")),
                tags$li("AffinityAccess.live relies on a consistent format for schedules on the affinity site and is liable to break when the affinity.com UI changes."),
                tags$li("All schedules are cached internally and updated once a day.  It takes a while to download the schedule the first time.")
            ),
            tags$h4("Acknowledgements"),
            tags$p("This utility is provided as a convenience for Oregon Youth Soccer administrators by ", a("href"="mailto:bill.kayser@ncsoccerclub.com", "Bill Kayser")," of North Clackamas Soccer Club.")
        ))
    })
    
    updateURLs <- \(title, newURL) {
        leagueURLs <- read.csv("URLS.csv")
        if (!(newURL %in% leagueURLs$url)) {
            leagueURLs <- bind_rows(leagueURLs, list(title=title, url = newURL))
            write.csv(leagueURLs, "URLS.csv", row.names = F)
            updateSelectizeInput(session, 'scUrl', choices = setNames(leagueURLs$url, leagueURLs$title), server = TRUE)
        }
    }
    
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


