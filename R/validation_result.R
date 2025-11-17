#' ValidationResult R6 Class
#'
#' @description An R6 class for storing three-tier validation results from Excel file imports.
#' Contains data (if validation passed), critical errors (blocking issues), and warnings (non-blocking issues).
#'
#' @export
ValidationResult <- R6::R6Class(
  "ValidationResult",
  public = list(
    #' @field data Successfully processed data if no critical errors exist
    data = NULL,

    #' @field critical_errors List of critical errors that prevent data usage
    critical_errors = list(),

    #' @field warnings List of non-critical warnings
    warnings = list(),

    #' @field has_critical_errors Boolean indicating presence of critical errors
    has_critical_errors = FALSE,

    #' @field has_warnings Boolean indicating presence of warnings
    has_warnings = FALSE,

    #' @field validation_timestamp Timestamp when validation was performed
    validation_timestamp = NULL,

    #' @field file_path Path to the validated file
    file_path = NULL,

    #' @field validation_type Type of validation performed (e.g., "scenarios", "plots", "project")
    validation_type = NULL,

    #' @description
    #' Initialize a new ValidationResult object
    #' @param file_path Path to the file being validated
    #' @param validation_type Type of validation being performed
    initialize = function(file_path = NULL, validation_type = NULL) {
      self$file_path <- file_path
      self$validation_type <- validation_type
      self$validation_timestamp <- Sys.time()
      self$critical_errors <- list()
      self$warnings <- list()
    },

    #' @description
    #' Add a critical error to the validation result
    #' @param category Error category (e.g., "Structure", "Missing Fields", "Invalid References")
    #' @param message Error message
    #' @param details Additional details (sheet name, row numbers, etc.)
    add_critical_error = function(category, message, details = NULL) {
      error_entry <- list(
        category = category,
        message = message,
        details = details,
        timestamp = Sys.time()
      )

      # Group by category if it exists, otherwise create new category
      if (!is.null(self$critical_errors[[category]])) {
        self$critical_errors[[category]] <- append(
          self$critical_errors[[category]],
          list(error_entry)
        )
      } else {
        self$critical_errors[[category]] <- list(error_entry)
      }

      self$has_critical_errors <- TRUE
    },

    #' @description
    #' Add a warning to the validation result
    #' @param category Warning category
    #' @param message Warning message
    #' @param details Additional details
    #' @param recommendation Suggested action to resolve the warning
    add_warning = function(category, message, details = NULL, recommendation = NULL) {
      warning_entry <- list(
        category = category,
        message = message,
        details = details,
        recommendation = recommendation,
        timestamp = Sys.time()
      )

      # Group by category
      if (!is.null(self$warnings[[category]])) {
        self$warnings[[category]] <- append(
          self$warnings[[category]],
          list(warning_entry)
        )
      } else {
        self$warnings[[category]] <- list(warning_entry)
      }

      self$has_warnings <- TRUE
    },

    #' @description
    #' Set the successfully processed data
    #' @param data The processed data to store
    set_data = function(data) {
      if (!self$has_critical_errors) {
        self$data <- data
      } else {
        warning("Cannot set data when critical errors exist")
      }
    },

    #' @description
    #' Get a summary of the validation result
    #' @return A list containing counts and summaries
    get_summary = function() {
      list(
        validation_type = self$validation_type,
        file_path = self$file_path,
        timestamp = self$validation_timestamp,
        has_data = !is.null(self$data),
        critical_error_count = sum(sapply(self$critical_errors, length)),
        warning_count = sum(sapply(self$warnings, length)),
        critical_error_categories = names(self$critical_errors),
        warning_categories = names(self$warnings)
      )
    },

    #' @description
    #' Get formatted messages for display
    #' @param type Type of messages to retrieve ("critical", "warning", or "all")
    #' @return Character vector of formatted messages
    get_formatted_messages = function(type = "all") {
      messages <- character()

      if (type %in% c("critical", "all") && self$has_critical_errors) {
        for (category in names(self$critical_errors)) {
          for (error in self$critical_errors[[category]]) {
            msg <- sprintf("[%s] %s", category, error$message)
            if (!is.null(error$details)) {
              msg <- paste(msg, sprintf("(%s)", error$details))
            }
            messages <- c(messages, msg)
          }
        }
      }

      if (type %in% c("warning", "all") && self$has_warnings) {
        for (category in names(self$warnings)) {
          for (warning in self$warnings[[category]]) {
            msg <- sprintf("[%s] %s", category, warning$message)
            if (!is.null(warning$details)) {
              msg <- paste(msg, sprintf("(%s)", warning$details))
            }
            if (!is.null(warning$recommendation)) {
              msg <- paste(msg, sprintf("- Recommendation: %s", warning$recommendation))
            }
            messages <- c(messages, msg)
          }
        }
      }

      return(messages)
    },

    #' @description
    #' Check if validation passed (no critical errors)
    #' @return Boolean indicating if validation passed
    is_valid = function() {
      return(!self$has_critical_errors)
    },

    #' @description
    #' Convert to list for easy serialization
    #' @return List representation of the validation result
    to_list = function() {
      list(
        data = self$data,
        critical_errors = self$critical_errors,
        warnings = self$warnings,
        has_critical_errors = self$has_critical_errors,
        has_warnings = self$has_warnings,
        validation_timestamp = self$validation_timestamp,
        file_path = self$file_path,
        validation_type = self$validation_type,
        summary = self$get_summary()
      )
    },

    #' @description
    #' Print method for ValidationResult
    print = function() {
      cat("ValidationResult\n")
      cat("================\n")
      cat("Type:", self$validation_type, "\n")
      cat("File:", self$file_path, "\n")
      cat("Timestamp:", format(self$validation_timestamp, "%Y-%m-%d %H:%M:%S"), "\n")
      cat("\n")

      if (self$has_critical_errors) {
        cat("Critical Errors:", sum(sapply(self$critical_errors, length)), "\n")
        for (category in names(self$critical_errors)) {
          cat("  -", category, ":", length(self$critical_errors[[category]]), "error(s)\n")
        }
      } else {
        cat("Critical Errors: None\n")
      }

      if (self$has_warnings) {
        cat("Warnings:", sum(sapply(self$warnings, length)), "\n")
        for (category in names(self$warnings)) {
          cat("  -", category, ":", length(self$warnings[[category]]), "warning(s)\n")
        }
      } else {
        cat("Warnings: None\n")
      }

      cat("\n")
      cat("Status:", ifelse(self$is_valid(), "VALID (can proceed)", "INVALID (fix critical errors)"), "\n")
    }
  )
)