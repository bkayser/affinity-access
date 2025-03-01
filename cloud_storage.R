library(googleCloudStorageR)

getStoredVersion <- \(scheduleKey) {
    metadata <- gcs_list_objects(detail="summary") |>
        # Convert the dates from UTC to Pacific.  The API messes it up.
        mutate(updated = force_tz(updated, tzone = "UTC") |> with_tz("America/Los_Angeles"))
    
    now <- with_tz(Sys.time(), "America/Los_Angeles")
    
    fileIndex <- which(str_ends(metadata$name, scheduleKey))
    if (is_empty(fileIndex)) return(NULL)
    timestamp <- metadata$updated[fileIndex]
    filename <- metadata$name[fileIndex]
    
    # Check the local file
    fileinfo <- file.info(filename)
    
    cacheFileMtime <- with_tz(fileinfo$mtime, "America/Los_Angeles")
    
    if (!is.na(fileinfo$mtime) && date(cacheFileMtime) == date(now)) {
        load(filename) # schedule
        return(schedule)
    } else if (date(metadata$updated[fileIndex]) == date(now)) {
        dir.create(dirname(filename), recursive = T)
        gcs_load(file=filename, envir=environment())  # "schedule"
        return(schedule)
    }
    return(NULL)
}

# The schedule is a list object with  keys "title" and "schedule" (a table)
# 
storeVersion <- \(scheduleKey, schedule) {
    file <- str_c("schedules/", schedule$title, "/", scheduleKey)
    dir.create(dirname(file), recursive = T)
    gcs_save(schedule, file=file) # schedule
}

getLiveScheduleList <- \() {
    metadata <- gcs_list_objects(detail="summary", prefix="schedules") |>
        dplyr::filter(name != "schedules/")
    if (nrow(metadata) == 0) return(list())
    parts <- str_match(metadata$name, "schedules/([^/]*)/(.*)$")
    return(setNames(parts[,3], parts[,2]))
}

