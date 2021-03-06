get_ga_dph_vaccine_orders_list <- function() {
  library(tidyverse)
  library(pdftools)
  library(assertthat)

  download.file("https://dph.georgia.gov/document/document/vaccine-orders-list/download",
                destfile = "data/vaccine_orders_list_raw.pdf")

  # Split PDF into list, one entry per page
  pdf_text_by_page <- pdf_text("data/vaccine_orders_list_raw.pdf") %>%
    map(~str_split(., "\\n")[[1]])

  # as of 2021-02-12, these are the expected PDF headers
  # Function will error out if it doesn't find these
  headers_expected <- c(
    "Provider Name/Clinic Name","County",
    "Pfizer Doses Requested","Total Allocated - Pfizer",
    "Moderna Doses Requested","Total Allocated - Moderna"
  )
  headers_raw <- pdf_text_by_page[[1]][1]
  assert_that(all(map_lgl(headers_expected,
                          ~str_detect(headers_raw, .))),
              msg = paste0("Failed check - PDF Headers not in list: ",
                           paste(headers_expected, collapse = ", ")))

  # Remove first line of each pdf page list item, and combine into one character vector
  pdf_text_no_headers <-
    map(pdf_text_by_page,
        ~(.[2:length(.)])) %>%
    unlist()
  # Assuming entries are separated by at least 2 spaces, split each line by that,
  # and convert to a data frame (with dummy headers col1, col2, etc)
  pdf_text_no_headers_as_df <-
    pdf_text_no_headers %>%
    str_split(" {2,}") %>% .[!map_lgl(., ~(length(.) == 1))] %>%
    map_df(~tibble(col1 = .[1], col2 = .[2], col3 = .[3],
                   col4 = .[4], col5 = .[5], col6 = .[6]))
  # Add headers to the data frame with dummy headers and write to CSV
  pdf_text_as_df <- pdf_text_no_headers_as_df
  names(pdf_text_as_df) <- headers_expected
  write_csv(pdf_text_as_df, "data/vaccine_orders_list.csv")
}

get_ga_dph_vaccine_orders_list()
