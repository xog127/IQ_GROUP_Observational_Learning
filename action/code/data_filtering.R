### Select Pavlovia files for the action-only study (one session per participant).
### Include participants with demographics Status APPROVED or AWAITING.

library(readxl)
library(dplyr)
library(purrr)
library(stringr)

base_dir <- normalizePath("../main_data", winslash = "/", mustWork = TRUE)
all_data_dir <- file.path(base_dir, "raw_data")
demo_dir <- file.path(base_dir, "demographics")
output_dir <- file.path(base_dir, "filtered_data")

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# The action-only study has one session, with separate female/male folders.
sessions <- c("female_session1", "male_session1")

read_any <- function(filepath) {
  ext <- tools::file_ext(filepath)
  if (tolower(ext) %in% c("xlsx", "xls")) {
    return(readxl::read_excel(filepath))
  } else {
    return(read.csv(filepath, stringsAsFactors = FALSE))
  }
}

audit_log <- list()

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
  
  # No manual override: select only APPROVED and AWAITING participants.
  eligible_demo <- demo_df %>%
    mutate(across(everything(), as.character)) %>%
    filter(
      str_to_upper(str_squish(Status)) %in% c("APPROVED", "AWAITING REVIEW"),
      !is.na(Participant.id),
      Participant.id != ""
    )
  
  eligible_ids <- unique(eligible_demo$Participant.id)
  
  # Match raw files to eligible participant IDs.
  # Match raw files to eligible participant IDs
  raw_folder <- file.path(all_data_dir, session_name)
  
  raw_files <- list.files(
    raw_folder,
    pattern = "\\.(csv|xlsx|xls)$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  
  cat("\nSession:", session_name, "\n")
  cat("Raw folder exists:", dir.exists(raw_folder), "\n")
  cat("Total raw files found:", length(raw_files), "\n")
  cat("Eligible participants:", length(eligible_ids), "\n")
  
  # Match filenames with participant IDs
  id_pattern <- paste(eligible_ids, collapse = "|")
  
  matched_files <- raw_files[
    str_detect(basename(raw_files), id_pattern)
  ]
  
  matched_ids_in_files <- str_extract(
    basename(matched_files),
    id_pattern
  )
  
  missing_ids <- setdiff(eligible_ids, matched_ids_in_files)
  
  cat("Matched files:", length(matched_files), "\n")
  cat("Unique participants matched:", length(unique(matched_ids_in_files)), "\n")
  cat("Missing participants:", length(missing_ids), "\n")
  
  if (length(eligible_ids) > 0) {
    id_pattern <- paste(eligible_ids, collapse = "|")
    matched_files <- raw_files[str_detect(basename(raw_files), id_pattern)]
    matched_ids_in_files <- str_extract(basename(matched_files), id_pattern)
  } else {
    matched_files <- character(0)
    matched_ids_in_files <- character(0)
  }
  
  # Read matched files, skipping empty or unreadable files
  behavioral_list <- lapply(matched_files, function(f) {
    
    tryCatch({
      
      df <- read_any(f)
      
      if (nrow(df) == 0 || !"participant" %in% names(df)) {
        message("Skipping empty/invalid file: ", basename(f))
        return(NULL)
      }
      
      df$participant <- as.character(df$participant)
      df$source_session <- session_name
      df$source_file <- basename(f)
      
      return(df)
      
    }, error = function(e) {
      message("Skipping unreadable file: ", basename(f))
      return(NULL)
    })
  })
  
  # Remove unreadable files
  valid_files <- matched_files[!sapply(behavioral_list, is.null)]
  
  # Combine valid data
  behavioral_data <- bind_rows(behavioral_list) %>%
    filter(participant %in% eligible_ids)
  
  # Update audit log based on successfully read data
  matched_ids <- unique(behavioral_data$participant)
  missing_ids <- setdiff(eligible_ids, matched_ids)
  
  audit_log[[session_name]] <<- data.frame(
    session = session_name,
    target_count = length(eligible_ids),
    matched_files = length(valid_files),
    missing_count = length(missing_ids),
    missing_ids = if (length(missing_ids) > 0) {
      paste(missing_ids, collapse = ", ")
    } else {
      "None"
    }
  )
  
  cat("Successfully read files:", length(valid_files), "\n")
  cat("Unique participants:", length(matched_ids), "\n")
  cat("Missing participants:", length(missing_ids), "\n")
  
  if (length(missing_ids) > 0) {
    print(missing_ids)
  }
  
  if (nrow(behavioral_data) == 0) return(NULL) %>% bind_rows()
  
  session_data <- behavioral_data %>%
    left_join(eligible_demo, by = c("participant" = "Participant.id"))
  
  session_out_file <- file.path(output_dir, paste0(session_name, "_approved_awaiting_with_demo.csv"))
  write.csv(session_data, session_out_file, row.names = FALSE)
  message("Saved: ", session_out_file)
  cat(sprintf("%s: %d approved/awaiting participants\n", session_name, length(eligible_ids)))
  
  return(session_data)
})

all_eligible_combined <- bind_rows(session_results)

master_file <- file.path(output_dir, "all_action_only_approved_awaiting_with_demo.csv")
write.csv(all_eligible_combined, master_file, row.names = FALSE)
message("\nMaster combined file saved with demographics: ", master_file)

if (length(audit_log) > 0) print(bind_rows(audit_log))