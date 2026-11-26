### This file is to select Pavlovia data files that are used for analysis, excluding returned or screened out participants. 
### Participants who did not participate in both Sessions will be filtered in the main analysis code.

library(readxl)
library(dplyr)
library(purrr)
library(stringr)

base_dir     <- "../main_data/preprocessing/"
all_data_dir <- file.path(base_dir, "raw_data")
demo_dir     <- file.path(base_dir, "demographics")
output_dir   <- file.path(base_dir, "../filtered_data")

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

sessions <- c("female_session1", "female_session2", "male_session1", "male_session2")

read_any <- function(filepath) {
  ext <- tools::file_ext(filepath)
  if (tolower(ext) %in% c("xlsx", "xls")) {
    return(readxl::read_excel(filepath))
  } else {
    return(read.csv(filepath, stringsAsFactors = FALSE))
  }
}
audit_log <- list()

# Join demographics for each session
session_results <- lapply(sessions, function(session_name) {
  message("\n--- Processing: ", session_name, " ---")
  demo_file <- list.files(
    path = demo_dir,
    pattern = paste0("^", session_name, "\\.(xlsx|xls|csv)$"),
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  if (length(demo_file) == 0) {
    warning("Demographics file missing for: ", session_name)
    return(NULL)
  }
  
  demo_df <- read_any(demo_file[1])
  colnames(demo_df) <- make.names(colnames(demo_df))
  
  demo_df <- demo_df %>%
    mutate(across(everything(), as.character))
  
  # Filter demographics for manual override (NO CODE participant - Completed experiment through direct experiment link)
  target_demo <- demo_df %>%
    filter(
      toupper(Status) == "APPROVED" |
        (session_name == "female_session2" & Participant.id == "66034de136822e2d301c3796")
    )
  
  target_ids <- target_demo$Participant.id
  
  #Match raw files
  raw_folder <- file.path(all_data_dir, session_name)
  raw_files  <- list.files(raw_folder, pattern = "\\.(csv|xlsx|xls)$", full.names = TRUE)
  
  id_pattern    <- paste(target_ids, collapse = "|")
  matched_files <- raw_files[str_detect(basename(raw_files), id_pattern)]
  
  matched_ids_in_files <- str_extract(basename(matched_files), id_pattern)
  missing_ids <- setdiff(target_ids, matched_ids_in_files)
  
  audit_entry <- data.frame(
    session        = session_name,
    target_count   = length(target_ids),
    matched_files  = length(matched_files),
    missing_count  = length(missing_ids),
    missing_ids    = ifelse(length(missing_ids) > 0, paste(missing_ids, collapse = ", "), "None")
  )
  audit_log[[session_name]] <<- audit_entry
  
  if (length(matched_files) == 0) return(NULL)
  
  
  behavioral_data <- lapply(matched_files, function(f) {
    df <- read_any(f)
    if ("participant" %in% colnames(df)) {
      df$participant <- as.character(df$participant)
    }
    df$source_session <- session_name
    df$source_file    <- basename(f)
    return(df)
  }) %>% bind_rows()
  
  session_data <- behavioral_data %>%
    left_join(target_demo, by = c("participant" = "Participant.id"))
  
  session_out_file <- file.path(output_dir, paste0(session_name, "_approved_with_demo.csv"))
  write.csv(session_data, session_out_file, row.names = FALSE)
  message("Saved: ", session_out_file)
  cat(sprintf("%s: %d approved\n", bind_rows(audit_log)$session, bind_rows(audit_log)$target_count))
  
  return(session_data)
})


all_approved_combined <- bind_rows(session_results)

master_file <- file.path(output_dir, "all_sessions_approved_combined_with_demo.csv")
write.csv(all_approved_combined, master_file, row.names = FALSE)
message("\nMaster combined file saved with demographics: ", master_file)