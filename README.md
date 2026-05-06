# Hiring, Overtime, and AI: VA is Processing Veterans’ Disability Claims Faster Than Ever 

## Overview

This repository contains the code to re-create the [data visual](https://public.flourish.studio/story/3642401/) from The War Horse story, [“Hiring, Overtime, and AI: VA is Processing Veterans’ Disability Claims Faster Than Ever.”](https://thewarhorse.org/ai-veterans-affairs-disability-claims/)

## Data

The War Horse obtained [weekly claims backlog data](https://www.benefits.va.gov/reports/detailed_claims_data.asp) from the U.S. Department of Veterans Affairs (VA). The backlog is defined as the number of claims for services normally requiring a rating decision — such as disability compensation and pension benefits — that have been pending for longer than 125 days. 

The processed data used in our visualization is available [here](https://github.com/The-War-Horse-News/faster-va-claims-processing/blob/main/data-output/claims_backlog.csv).

## Methodology

To understand how the claims backlog has changed over time, we [downloaded](https://github.com/The-War-Horse-News/faster-va-claims-processing/blob/main/scripts/download.R) spreadsheets providing weekly snapshots of the agency's workload between January 2016 and April 2026. We then [parsed](https://github.com/The-War-Horse-News/faster-va-claims-processing/blob/main/scripts/parse.R) the spreadsheets to identify the claims backlog volume each week. In some cases, we calculated the backlog using the percentage of claims pending for longer than 125 days and total claims volume. We attributed the backlog to the date provided in the title of each weekly report file.

## Limitations

More information about the weekly workload report is available [here](https://www.benefits.va.gov/REPORTS/mmwr/mmwr-walkthru-sep2023-0921-mlc.pdf). A visualization summarizing the backlog since 2013 is available [here](https://www.benefits.va.gov/reports/mmwr_va_claims_backlog.asp). 

## License

This data is released under a [Creative Commons BY-NC 4.0 license](https://creativecommons.org/licenses/by-nc/4.0/). You can  use it for noncommercial purposes if you attribute to The War Horse and link to [our reporting](https://thewarhorse.org/ai-veterans-affairs-disability-claims/).