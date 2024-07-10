library(jsonlite)

handle_user_input <- function(options, prompt, retry_prompt) {
  while (TRUE)
  {
    # Check if session is interactive
    interactive_session <- interactive()
    
    user_input <- NULL
    quit_on_timeout <- FALSE
    quit_on_noenv <- TRUE
    be_verbose <- FALSE
    timeout <- 3600
    afia_filename <- "afinputa.txt"
    afiq_filename <- "afinputq.txt"
    
    if (interactive_session) {
      # Print options
      if (be_verbose) {
        cat("Interactive session\n")
      }
      cat("Select an option:\n")
      for (i in seq_along(options)) {
        cat(i, ": ", options[i], "\n")
      }
      # Get user input
      user_input <- readline(prompt)
      if (be_verbose) {
        cat("Terminal user_input: ", user_input, "\n")
      }
    } else {
      # Read input from file
      if (be_verbose) {
        cat("Non Interactive session\n")
      }
      txid <- Sys.getenv("TXID")
      if (is.na(txid) || txid == '') {
        # txid = "TXID_1708137304985"
        if (be_verbose) {
          cat("NO TXID IN ENV:\n")
        }
        if (quit_on_noenv) {
          quit(save = "no",
               status = -1,
               runLast = FALSE)
        }
      }
      txid_dir <- Sys.getenv("TXID_DIR_AFI")
      if (is.na(txid_dir) || txid_dir == '') {
        # txid_dir = "/opt/lake/data/cloneid/module02/data/txdir"
        if (be_verbose) {
          cat("NO TXDIR IN ENV:\n")
        }
        if (quit_on_noenv) {
          quit(save = "no",
               status = -1,
               runLast = FALSE)
        }
      }
      
      cat(paste(
        c(
          "[BACKEND]",
          txid,
          gsub(":", "", prompt),
          paste(gsub(":", "", options), collapse = "|"),
          gsub(":", "", retry_prompt),
          txid
        ),
        collapse = "::"
      ), "\n")
      
      if (be_verbose) {
        cat(paste(c(txid_dir, afia_filename), collapse = "::"), "\n")
      }
      afia_filepath <- paste(c(txid_dir, afia_filename), collapse = "/")
      afiq_filepath <- paste(c(txid_dir, afiq_filename), collapse = "/")
      if (be_verbose) {
        cat(paste(c("FILE_WITH_INPUT", afia_filepath), collapse = "::"), "\n")
        cat(paste(c("FILE_WITH_INPUT", afiq_filepath), collapse = "::"), "\n")
      }
      start_wait <- Sys.time()
      # until file avail or timeout
      while (TRUE) {
        if (file.exists(afia_filepath)) {
          user_input <- readLines(afia_filepath, n = 1)
          if (length(user_input) > 0) {
            if (be_verbose) {
              cat(paste(c(
                "File User Input", user_input
              ), collapse = "="), "\n")
            }
		    file.remove(afia_filepath)
		    file.remove(afiq_filepath)
            break
          }
          # }else{
          # 	if (be_verbose) {
          #     cat(paste(c(afia_filepath, "Does not exist"), collapse = " "), "\n")
          #   }
        }
        # quit on timeout
        if (difftime(Sys.time(), start_wait, units = "secs") > timeout) {
          if (be_verbose) {
            cat(c("Timeout error: File not found"), "\n")
          }
          if (quit_on_timeout) {
            quit(save = "no",
                 status = -1,
                 runLast = FALSE)
          }
        }
        if (be_verbose) {
          cat(paste(c("Waiting for", afia_filepath), collapse = " "), "\n")
        }
        Sys.sleep(1)
      }
      if (be_verbose) {
        cat("File user_input: ", user_input, "\n")
      }
    }
    
    # Bypass when starts with '#'
    if (startsWith(user_input, '#')) {
      return(gsub("#", "", user_input))
    }
    
    suppressWarnings(choice <- as.numeric(user_input))
    
    if (be_verbose) {
      cat("choice: ", choice, "\n")
    }
    
    # If the input is a number and within the range of options
    if (!is.na(choice) &&
        choice >= 1 && choice <= length(options)) {
      return(choice)
    } else {
      # Check if the input matches any option
      matched_option <-
        which(tolower(options) == tolower(user_input))
      if (length(matched_option) > 0) {
        return(matched_option)
      } else {
        cat(retry_prompt, "\n\n")
      }
    }
  }
}


TEST_handle_user_input <- function(options, prompt, retry_prompt) {
  selected_option <- handle_user_input(options, prompt, retry_prompt)
  
  
  cat("selected_option: ", selected_option, "\n")
  cat("You selected:",
      ifelse(startsWith(as.character(selected_option), '#'), selected_option, options[selected_option]),
      "\n")
  cat("You selected:", jsonlite::toJSON(c(
    'x', ifelse(startsWith(as.character(selected_option), '#'), selected_option, options[selected_option])
  )), "\n")
}



# Usage
options <- c("Option A", "Option B", "Option C")
prompt <- "Enter option number or type your own:"
retry_prompt <-
  "Invalid input. Please enter a valid option number or type one of the provided options."
TEST_handle_user_input(options, prompt, retry_prompt)


Sys.sleep(10)


# Usage
options <- c("Yes", "No")
prompt <- "Select option:"
retry_prompt <-
  "Invalid input. Please enter a valid option number or type one of the provided options."
TEST_handle_user_input(options, prompt, retry_prompt)


Sys.sleep(10)


# Usage
options <- c("A", "B", "C")
prompt <- "Select:"
retry_prompt <- "Invalid input. Please retry"
TEST_handle_user_input(options, prompt, retry_prompt)


Sys.sleep(10)






# B = jsonlite::fromJSON('[{"a":[1],"b":[2]},{"x":[1],"y":[2],"z":[3]}]')
# Rscript --vanilla manageInput1.R
