
toPlayMetrics <- \(raw) {
    rename(raw,
           id.affinity = id) |>
        mutate(date = str_c(Date, " ", Time),
               Level = extractAge(Division),
               Duration = 10 + 2 * ifelse(Level < 'U9', 20,
                                 ifelse(Level < 'U11', 25,
                                        ifelse(Level < 'U13', 30,
                                               ifelse(Level < 'U15', 35,
                                                      ifelse(Level < 'U17', 40, 45))))),
               Kickoff = strptime(date, "%Y-%m-%d %I:%M %p"),
               Day = as.Date(Kickoff),
               Venue = str_remove(Field, " - .*$"),
               Date = strftime(Kickoff, "%m/%d/%Y"),
               `Start Time` = strftime(Kickoff, "%I:%M:%S %p"),
               `Field Name` = Field) |>
        arrange(Day, `Field Name`, Kickoff) |>
        select(Date,
               `Start Time`,
               `Field Name`,
               Duration,
               `Division Name` = Division,
               `Home Team Name`= Home,
               `Away Team Name` = Away,
               `External Game ID`= id.affinity) 
}

toReftown <- \(raw) {
    mutate(raw,
           Level = extractAge(Division),
           Date = strftime(Date, "%m/%d/%Y"),
           CrewType = ifelse(Level < 'U11', 'Single', 'Diagonal'),
           SubLocation = str_match(Field, " - (.*$)")[,2], # Extract the Sublocation of the field
           Location = str_remove(Field, " - .*$"), # Strip out the Sublocation of the field
           SubLocation = str_remove(SubLocation, "^PC #")) |> # Strip out excess stuff from Sublocation
        select(Date,
               Time,
               Type = Gender,
               Level,
               Location,
               SubLocation,
               Home,
               Visitor = Away,
               CrewType)
}

Ages <- c('U6', 'K', 'U7', '1st Grade', 'U8', '2nd Grade', 'U9', '3rd Grade', 'U10', '4th Grade', 'U11', '5th Grade', 'U12', '6th Grade', 'U13', '7th Grade', 'U14', '8th Grade', 'U15', 'HS', 'U16', 'U17', 'U18', 'U19')
extractAge <- \(division) {
    ifelse(str_detect(division, "^\\d"), division, # Grade level
           ifelse(str_detect(division, "^HS"), "HS",   # High School
                  str_match(division, "^[BG]?(U\\d\\d?) ")[,2])) |> 
        factor(Ages, ordered=T)
}

# all$Division |> sort() |> unique() |> extractAge() |> unique() |> sort()
## Test code
## 

# all <- lapply(dir("cache/schedules", ".*RDS", full.names = T),
#        \(file){
#            return(readRDS(file))
#        }) |> bind_rows()
# 
# toReftown(sample_n(all, 40)) |> View()
# 
# toPlayMetrics(all) |> View()
# 
# filter(all, Field == 'Meldrum Bar Park')

