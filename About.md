This utility allows you to download a CSV file from a live schedule on the SportsConnect site.

#### How to Use [AffinityAccess.live](https://affinityaccess.live)

There is a selector for known schedules on the OYSA Affinity site.  If
your schedule does not appear in the list, try entering the URL
provided by the league and hit the add button.  Once added, the
schedule should appear in the drop down menu until the application is
updated on the server.
                  
After selecting the schedule, you have a choice of several different
download formats to choose from for preview and download:

* *Raw* - a generic format corresponding to the affinity schedule tables.
* *PlayMetrics Upload Ready* - a format with columns mapped to columns
  known by PlayMetrics on schedule import.  It will likely be
  necessary to map field names and team names during the import.
* *Reftown Upload Ready* - a format suitable for upload to the referee
  assigning platform [Reftown.com](https://reftown.com).

Hit the Preview button to browse the schedule or the Download button
to download the CSV. The first time a schedule downloads for the day
there will be a 10-20 second delay while the server is scanning pages
on the affinity site."),

Enter any part of the team or club name to select only the games with
that name in the Home or Away columns.  This affects the data that
will be downloaded.  Use the search button to search all fields in the
schedule.  Note that this will not change what is in the downloaded
file.

#### Caveats

* Tournament (bracket) schedules are not available.
* AffinityAccess.live is currently beta testing.  Please report any
  issues to
  [admin@affinityaccess.live](mailto:admin@affinityaccess.live).
* AffinityAccess.live relies on a consistent format for schedules on
  the affinity site and is liable to break when the affinity.com UI
  changes.
* All schedules are cached internally and updated once a day.  It
  takes a while to download the schedule the first time.

#### Source

The [source for AffinityAccess.live](https://github.com/bkayser/affinity-access) is available on github under GPL version 3.

#### Acknowledgements

This utility is provided as a convenience for Oregon Youth Soccer
administrators by [Bill Kayser](mailto:bill.kayser@ncsoccerclub.com)
of North Clackamas Soccer Club.
