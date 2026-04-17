# Name: parse.R
# Date: 2026-04-08
# Purpose: Parse the top line claims number only from Monday Morning Workload Reports from 2026 to the present

# Libraries
library(dplyr)
library(ggplot2)
library(lubridate)
library(assertthat)
library(stringr)
library(here)

# Parameters
dir_raw <- here("data-raw/")
dir_output <- here("data-output")
file_output <- here("data-output/claims_backlog.csv")

# Functions

rating_bundle <- function(x) {
  # Reads the sheet titled 'Rating Bundle - SOJ' 
  sheets <- readxl::excel_sheets(x)
  if ("Rating Bundle - SOJ" %in% sheets){
    readxl::read_excel(path = x, sheet = "Rating Bundle - SOJ", skip = 10, col_types = "text") |> 
      mutate(
        path = x
      )
  }
}

not_rating_bundle <- function(x) {
  # Reads the third sheet if none titled 'Rating Bundle - SOJ' are present
  sheets <- readxl::excel_sheets(x)
  if (!"Rating Bundle - SOJ" %in% sheets){
    readxl::read_excel(path = x, sheet = 3, skip = 10, col_types = "text") |> 
      mutate(
        path = x
      )
  }
}

clean_data <- function(x) {
  x |> 
    mutate(
      value = str_replace_all(value, "%20", " "),
      date = str_extract(value, "\\d+-\\d+-\\d+"),
      date = if_else(is.na(date), str_extract(value, "\\d+_\\d+_\\d+"), date),
      date = if_else(value == "https://www.benefits.va.gov/REPORTS/mmwr/2014/MMWL_01-27_2014.xls", "01-27-2014", date),
      date = 
        case_when(
          str_length(date) <= 8 ~ mdy(date),
          str_detect(date, "\\d{2}-\\d{2}-\\d{4}") ~ mdy(date),
          str_detect(date, "\\d{2}_\\d{2}_\\d{4}") ~ mdy(date),
          str_detect(date, "\\d{4}-\\d{2}-\\d{2}") ~ ymd(date),
          str_detect(date, "\\d{4}_\\d{2}_\\d{2}") ~ ymd(date),
          TRUE ~ mdy(date)
        )
  ) |> 
  select(pending_more_than_125, value, date) |> 
  arrange(date)
}

safe_convert <- function(x) {
  as.double(str_remove_all(x, ","))
}

# Code

# Read in the files
files_input <- list.files(dir_raw, full.names = TRUE)
input <- purrr::map_dfr(files_input, ~ rating_bundle(.))
input2 <- purrr::map_dfr(files_input, ~ not_rating_bundle(.))

# Create dir_output if it does not exist
  if (!dir.exists(dir_output)) {
    dir.create(dir_output)
  }

joined <-
  # Stack data from the two main types of files on top of one another
  bind_rows(
    input |> 
    filter(`...3` %in% c("Compensation Total", "USA - All Missions Total")) |> 
    select(pending_more_than_125 = `...5`, value = path) |> 
    # Changes data from string to double, removing any commas first
    mutate(pending_more_than_125 = safe_convert(pending_more_than_125)) |>
    clean_data(),
    input2 |> 
    filter(`...1` == "USA TOTAL*") |> 
    rename("value" = path) |> 
    # If no number of pending claims is available in this tab, 
    # use the percentage of pending claims and the number
    # of pending claims to calculate it.
    mutate(
      pending_more_than_125 = 
        safe_convert(`# Pending`) * safe_convert(`Percentage Pending > 125 days (Backlog)`)
    ) |>
    clean_data()
  ) |> 
  arrange(date) |> 
  select(-value)

## SPOT CHECKS

january_2021 <-
  joined |> 
  filter(date == mdy("01-25-2021")) |> 
  pull(pending_more_than_125)

are_equal(january_2021, 211443)

april_2026 <-
  joined |> 
  filter(date == mdy("04-04-2026")) |> 
  pull(pending_more_than_125)

are_equal(april_2026, 81775)

january_2016 <-
  joined |> 
  filter(date == mdy("01-18-2016")) |> 
  pull(pending_more_than_125)

are_equal(january_2016, 78113)

## CHECK DATA COMPLETENESS

# Define start and end period for data
start <- ymd("2016-01-01")
end <- ymd(Sys.Date())

# Count full weeks only
weeks_int <- interval(start, end)
weeks_count <- round(time_length(weeks_int, unit = "weeks"))

# Get list of data weeks
data_weeks <-
  joined |> 
  filter(date >= start) |> 
  distinct(date) |> 
  pull(date)

num_rows <- length(data_weeks)

are_equal(num_rows, weeks_count)

## WRITE OUT FINAL DATA
readr::write_csv(joined, file_output)