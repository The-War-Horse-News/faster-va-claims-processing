# Name: download.R
# Date: 2026-04-08
# Purpose: Download Monday Morning Workload Reports from 2026 to the present

# Libaries
library(tidyr)
library(dplyr)
library(rvest)
library(stringr)
library(purrr)
library(lubridate)
library(here)

# Parameters
url_claims <- "https://www.benefits.va.gov/reports/detailed_claims_data.asp"
url_root <- "https://www.benefits.va.gov${.}"
dir_raw <- here("data-raw/")

# Functions
safe_download <- function(x) {
  # A wrapper around download.file()
  # Create dir_raw if it does not exist
  if (!dir.exists(dir_raw)) {
    dir.create(dir_raw)
  }

  # Extract only the name of the file to download
  d <- str_c(dir_raw, str_extract(x, pattern = "(?<=\\d{4}/).*$"))

  # Download file x if it is not already on disk
  if (!file.exists(d)) {
    download.file(
        url = x, 
        # Extract the last part of the URL to be the file name
        destfile = d
    )
    # Pause to avoid too many requests
    Sys.sleep(1)
  } else {
    # Skip if file already downloaded
    cat(str_interp("Skipping. File exists: ${x}"))
  }

}

process_date <- function(x) {
  # Parses the date given in the title of the spreadsheet.
  x |> 
    mutate(
      # Extract the date based on the URL path to the spreadsheet  
      date = str_extract(value, "\\d+-\\d+-\\d+"),
      # If the date is still missing, try replacing dashes with underscores
      date = if_else(is.na(date), str_extract(value, "\\d+_\\d+_\\d+"), date),
      # Finally, parse a single case that uses both underscores and dashes
      date = if_else(value == "https://www.benefits.va.gov/REPORTS/mmwr/2014/MMWL_01-27_2014.xls", "01-27-2014", date),
      # Convert string dates to a date data type in R
      date = 
        case_when(
          # Parses dates written in month-day-year format, with only a two-digit year
          str_length(date) <= 8 ~ mdy(date),
          # Also use the month-day-year parser for dates with a full year
          str_detect(date, "\\d{2}-\\d{2}-\\d{4}") ~ mdy(date),
          # Also use month-day-year parser if underscores used in title
          str_detect(date, "\\d{2}_\\d{2}_\\d{4}") ~ mdy(date),
          # Parse by year-month-day format with dashes
          str_detect(date, "\\d{4}-\\d{2}-\\d{2}") ~ ymd(date),
          # Parse by year-month-day format with underscores
          str_detect(date, "\\d{4}_\\d{2}_\\d{2}") ~ ymd(date),
          # All other dates are mdy
          TRUE ~ mdy(date)
        )
    )
}

# Code

# Read in the webpage with VA claims data
page <- read_html(url_claims)

# Extract all URLs to excel files
urls <-
  page |> 
  # Extract all a tags, which is where the links are
  html_elements("a") |> 
  # Extract the links themselves
  html_attr("href") |> 
  # Filter only to links that contain the string 'xls' (will also include xlsm and xlsx files)
  str_subset("xls") |> 
  # Construct full links, not just the second half of the link
  map_chr(~ str_interp(url_root))

# Extract all of the dates when reports were issued
weekly <-
  urls |>
  # Drop any duplicate URLs
  unique() |> 
  as_tibble() |> 
  process_date() |> 
  mutate(
    # Replace any spaces with %20 so that files download withour errors
    value = str_replace_all(string = value, pattern = " ", replacement = "%20"),
    year = year(date)
  ) |> 
  arrange(date)

# Loop through the list of Excel file URLs and download each one between 2016 and the present
map(
  weekly |> 
    filter(year >= 2016) |> 
    pull(value), 
  ~ safe_download(.)
)

