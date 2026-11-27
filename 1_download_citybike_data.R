# 1. Load packages (conflicted first so all conflicts throw errors)
library(conflicted)
library(dplyr)
library(readr)
library(purrr)
library(lubridate)

# Declare preferred functions where conflicts occur
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

# 2. Define years (2021-2025) and active city bike months (April-October)
years <- 2021:2025
months <- sprintf("%02d", 4:10)

# 3. Create output directory and increase download timeout
data_dir <- "hsl_citybike_2021_2025"
dir.create(data_dir, showWarnings = FALSE)
options(timeout = 300)

# 4. Download monthly CSV files from HSL Open Data
for (y in years) {
  for (m in months) {
    file_name <- paste0(y, "-", m, ".csv")
    url <- paste0("https://dev.hsl.fi/citybikes/od-trips-", y, "/", file_name)
    dest_path <- file.path(data_dir, file_name)
    
    if (!file.exists(dest_path)) {
      message("Downloading ", file_name, "...")
      tryCatch({
        status <- download.file(url, destfile = dest_path, mode = "wb", quiet = TRUE)
        if (!identical(status, 0L) || !file.exists(dest_path) || file.info(dest_path)$size == 0) {
          if (file.exists(dest_path)) file.remove(dest_path)
          message("Skipped ", file_name, " (download failed or empty).")
        }
      }, error = function(e) {
        if (file.exists(dest_path)) file.remove(dest_path)
        message("Skipped ", file_name, " (not found on server).")
      })
    }
  }
}

# 5. Locate downloaded CSVs and ensure at least one exists
files <- list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)
stopifnot("No CSV files found in data_dir" = length(files) > 0)

# 6. Read and combine all monthly CSVs into one table
trips_21_25 <- map(files, ~ read_csv(.x, show_col_types = FALSE)) %>%
  list_rbind()

# 7. Verify column names and trip counts per year
names(trips_21_25)

trips_21_25 %>%
  mutate(year = year(Departure)) %>%
  count(year)

