library(tidyverse)
library(rvest)
library(httr)

#
#  This library supports reading affinity schedule sites and downloading games
#  into a table.  
#  
#    jsonlite::fromJSON('https://connect.learning.ussoccer.com/certifications/public/licenses') |>
# https://oysa.affinitysoccer.com/tour/public/info/schedule_results2.asp?sessionguid=&flightguid=60117D6A-4704-4AD7-A6D7-060DD49CA496&tournamentguid=E641EA5D-D028-458F-8EB9-1EEB8DD4AE32
# https://oysa.affinitysoccer.com/schedule_results2.asp?sessionguid=&flightguid=6A0C4B7D-D913-4586-A343-1616F857A339&tournamentguid=E641EA5D-D028-458F-8EB9-1EEB8DD4AE32
# 

# league_home   <- "https://oysa.affinitysoccer.com/tour/public/info/accepted_list.asp?tournamentguid=E641EA5D-D028-458F-8EB9-1EEB8DD4AE32"
# games <- read_league(session, league_home)


read_league <- function(league_home) {
    session <- session("https://oysa.affinitysoccer.com")
    page <- read_html(session_jump_to(session, league_home))
    title <- html_text(html_element(page, css=".brand-logo")) |> str_trim()
    
    boys_home <- read_divisions(session, 
                                str_c(league_home, "&show=boys"),
                                "Boys")
    girls_home <- read_divisions(session,
                                 str_c(league_home, "&show=girls"),
                                 "Girls")

    return(list(schedule = bind_rows(boys_home, girls_home),
                title = title))
}

read_divisions <- function(session,
                           home,
                           gender) {
    schedule <- tibble()
    page <- read_html(session_jump_to(session, home))
    links <- html_elements(page, css='a[href^="schedule_results2.asp"]') |>
        sapply(function(link){
            return(XML::getRelativeURL(html_attr(link, 'href'), home))
        })
    for (division_page in links) {
        schedule <- bind_rows(schedule, 
                              read_division(session, division_page))
    }
    schedule$Gender = gender    
    return(schedule)
}
read_division <- function(session,
                          division_page) {
    page <- read_html(session_jump_to(session, division_page))
    division_name <- html_element(page, css="span.title") |> html_text() |> str_sub(18)
    tables <- html_elements(page, css="center + table")
    dates <- sapply(html_children(html_elements(page, css="p + center")),
                    \(elem) { 
                        return(html_text(elem) |>
                                   str_extract("\\w+ \\d\\d,.*$") |>
                                   strptime("%B %d, %Y")) |>
                            as.Date()
                    }
    )
    
    i <- 1
    games <- tibble()
    for (table in tables) {
        date <- dates[[i]]
        i <- i + 1
        gamerows <- html_elements(table, "tr") |> tail(-1)
        
        for (game in gamerows) {
            attrs <- list()
            cells <- html_children(game)
            attrs$Division <- str_remove(division_name, "^(Boys|Girls) ")
            attrs$id <- html_text(cells[[1]]) |> str_trim() |> as.integer()
            attrs$Field <- str_c(html_text(cells[[2]]) |> str_trim(),
                                 " - ",
                                 html_text(cells[[4]]) |> str_trim())
            attrs$Time <- html_text(cells[[3]]) |> str_trim() |> str_remove("^0")
            attrs$Date <- date
            attrs$Home <-  html_text(cells[[6]]) |> str_trim()
            if (html_text(cells[[8]]) |> str_starts("vs")) {
                attrs$Away <- html_text(cells[[9]]) |> str_trim()
            } else {
                attrs$Away <- html_text(cells[[8]]) |> str_trim()
            }
            games <- bind_rows(games, attrs)                                  
        }
    }
    return(games)
}

cache <- function(name='cache', namespace=NULL) {
    
    cachedir <- function() {
        d <- str_glue('cache/',name)
        if (!is.null(namespace)) {
            d <- str_glue(d, '/{namespace}')
        }
        return(d)
    }
    filename <- function(id, ext='RDS') {
        return(str_glue(cachedir(), '/{id}.', ext))
    }    
    if (!dir.exists(cachedir())) {
        dir.create(cachedir(), recursive = T)
    }
    get <- function(id) {
        f <- filename(as.character(id))
        if (file.exists(f)) {
            return(readRDS(f))
        } else {
            return(NULL)
        }
    }
    get_html <- function(id) {
        f <- filename(as.character(id), 'HTML')
        if (file.exists(f)) {
            return(xml2::read_html(f))
        } else {
            return(NULL)
        }
    }
    put <- function(id, data) {
        saveRDS(data, filename(as.character(id)))
    }
    put_html <- function(id, doc) {
        xml2::write_html(doc, filename(as.character(id), 'HTML'))
    }
    
    return(list(get = get, 
                put = put,
                get_html = get_html,
                put_html = put_html))
}


hashvalue <- function(string) {
    return(sapply(string, \(v) {
        return(str_sub(digest(v, algo = "md5"),  end=8))
    }))
}

