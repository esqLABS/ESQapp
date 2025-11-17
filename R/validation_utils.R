#' Validation Utilities for Excel File Import
#'
#' @description Functions to validate Excel configuration files using esqlabsR validation logic
#' and return structured ValidationResult objects with three-tier categorization:
#' - Critical Errors: Blocking issues that prevent import
#' - Warnings: Non-blocking issues that should be reviewed
#' - Data: Successfully processed data when no critical errors exist
#'

#' Safe wrapper for esqlabsR functions
#'
#' @description Executes a function and captures errors and warnings
#' @param expr Expression to execute
#' @return List with result, errors, and warnings
safe_execute <- function(expr) {
  errors <- character()
  warnings <- character()
  result <- NULL

  # Capture warnings
  withCallingHandlers(
    {
      # Capture errors
      result <- tryCatch(
        expr,
        error = function(e) {
          errors <<- c(errors, conditionMessage(e))
          NULL
        }
      )
    },
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  list(
    result = result,
    errors = errors,
    warnings = warnings
  )
}

#' Parse esqlabsR error messages to extract details
#'
#' @param message Error message from esqlabsR
#' @return List with category and details
parse_error_message <- function(message) {
  category <- "General"
  details <- NULL

  # Categorize based on message patterns
  if (grepl("missing|Missing", message)) {
    category <- "Missing Fields"
  } else if (grepl("duplicate|Duplicate|unique|Unique", message, ignore.case = TRUE)) {
    category <- "Uniqueness Violation"
  } else if (grepl("does not exist|doesn't exist|not found", message, ignore.case = TRUE)) {
    category <- "Invalid Reference"
  } else if (grepl("structure|Structure", message)) {
    category <- "Structure Error"
  } else if (grepl("format|Format|type|Type", message, ignore.case = TRUE)) {
    category <- "Format Error"
  } else if (grepl("empty|Empty", message, ignore.case = TRUE)) {
    category <- "Empty Data"
  }

  # Extract sheet name if present
  if (grepl("Sheet ['\"](\\w+)['\"]", message)) {
    sheet_match <- regmatches(message, regexpr("Sheet ['\"](\\w+)['\"]", message))
    details <- paste("Sheet:", gsub("Sheet ['\"]|['\"]", "", sheet_match))
  }

  # Extract row numbers if present
  if (grepl("row[s]? (\\d+)", message, ignore.case = TRUE)) {
    row_match <- regmatches(message, gregexpr("\\d+", message))
    if (length(row_match[[1]]) > 0) {
      details <- paste(details, "Rows:", paste(row_match[[1]], collapse = ", "))
    }
  }

  list(category = category, details = details)
}

#' Validate Project Configuration File
#'
#' @param file_path Path to the project configuration Excel file
#' @return ValidationResult object
#' @export
validate_project_configuration <- function(file_path) {
  result <- ValidationResult$new(file_path, "project_configuration")

  # Check if file exists
  if (!file.exists(file_path)) {
    result$add_critical_error(
      "File Access",
      "Project configuration file does not exist",
      file_path
    )
    return(result)
  }

  # Try to create project configuration using esqlabsR
  execution <- safe_execute({
    esqlabsR::createDefaultProjectConfiguration(path = file_path)
  })

  # Process errors as critical
  for (error in execution$errors) {
    parsed <- parse_error_message(error)
    result$add_critical_error(
      parsed$category,
      error,
      parsed$details
    )
  }

  # Process warnings
  for (warning in execution$warnings) {
    parsed <- parse_error_message(warning)
    result$add_warning(
      parsed$category,
      warning,
      parsed$details,
      recommendation = "Review and correct if necessary"
    )
  }

  # If successful, validate referenced files exist
  if (!result$has_critical_errors && !is.null(execution$result)) {
    pc <- execution$result

    # Check if referenced files exist
    file_checks <- list(
      scenarios = pc$scenariosFile,
      individuals = pc$individualsFile,
      populations = pc$populationsFile,
      models = pc$modelParamsFile,
      applications = pc$applicationsFile,
      plots = pc$plotsFile,
      data = pc$dataFile
    )

    for (file_type in names(file_checks)) {
      if (!is.na(file_checks[[file_type]]) && !is.null(file_checks[[file_type]])) {
        if (!file.exists(file_checks[[file_type]])) {
          result$add_warning(
            "File Reference",
            sprintf("%s file referenced but does not exist", file_type),
            file_checks[[file_type]],
            recommendation = sprintf("Create or update the %s file path", file_type)
          )
        }
      }
    }

    # Store the configuration if valid
    result$set_data(pc)
  }

  return(result)
}

#' Validate Scenarios Configuration File
#'
#' @param file_path Path to the scenarios Excel file
#' @param project_config Optional project configuration object for context
#' @return ValidationResult object
#' @export
validate_scenarios_file <- function(file_path, project_config = NULL) {
  result <- ValidationResult$new(file_path, "scenarios")

  if (!file.exists(file_path)) {
    result$add_critical_error(
      "File Access",
      "Scenarios file does not exist",
      file_path
    )
    return(result)
  }

  # Check required sheets
  sheets <- tryCatch(
    readxl::excel_sheets(file_path),
    error = function(e) {
      result$add_critical_error(
        "File Access",
        "Cannot read Excel file",
        conditionMessage(e)
      )
      return(NULL)
    }
  )

  if (is.null(sheets)) return(result)

  required_sheets <- c("Scenarios", "OutputPaths")
  missing_sheets <- setdiff(required_sheets, sheets)

  if (length(missing_sheets) > 0) {
    result$add_critical_error(
      "Structure Error",
      sprintf("Required sheets missing: %s", paste(missing_sheets, collapse = ", ")),
      file_path
    )
    return(result)
  }

  # Validate Scenarios sheet
  execution <- safe_execute({
    esqlabsR::readScenarioConfigurationFromExcel(file_path)
  })

  for (error in execution$errors) {
    parsed <- parse_error_message(error)
    result$add_critical_error(parsed$category, error, parsed$details)
  }

  for (warning in execution$warnings) {
    parsed <- parse_error_message(warning)
    result$add_warning(
      parsed$category,
      warning,
      parsed$details,
      recommendation = "Check scenario configuration for completeness"
    )
  }

  # Additional validation for OutputPaths
  output_paths <- safe_execute({
    readxl::read_excel(file_path, sheet = "OutputPaths")
  })

  if (!is.null(output_paths$result)) {
    # Check for required columns
    required_cols <- c("OutputPathId", "OutputPath")
    missing_cols <- setdiff(required_cols, names(output_paths$result))

    if (length(missing_cols) > 0) {
      result$add_critical_error(
        "Missing Fields",
        sprintf("OutputPaths sheet missing required columns: %s", paste(missing_cols, collapse = ", ")),
        "Sheet: OutputPaths"
      )
    }

    # Check for duplicate OutputPathIds
    if ("OutputPathId" %in% names(output_paths$result)) {
      duplicates <- output_paths$result$OutputPathId[duplicated(output_paths$result$OutputPathId)]
      if (length(duplicates) > 0) {
        result$add_critical_error(
          "Uniqueness Violation",
          sprintf("Duplicate OutputPathIds found: %s", paste(unique(duplicates), collapse = ", ")),
          "Sheet: OutputPaths"
        )
      }
    }
  }

  if (!result$has_critical_errors && !is.null(execution$result)) {
    result$set_data(list(
      scenarios = execution$result,
      output_paths = output_paths$result
    ))
  }

  return(result)
}

#' Validate Plots Configuration File
#'
#' @param file_path Path to the plots Excel file
#' @param scenarios_data Optional scenarios data for reference validation
#' @param observed_data Optional observed data for reference validation
#' @return ValidationResult object
#' @export
validate_plots_file <- function(file_path, scenarios_data = NULL, observed_data = NULL) {
  result <- ValidationResult$new(file_path, "plots")

  if (!file.exists(file_path)) {
    result$add_critical_error(
      "File Access",
      "Plots file does not exist",
      file_path
    )
    return(result)
  }

  sheets <- tryCatch(
    readxl::excel_sheets(file_path),
    error = function(e) {
      result$add_critical_error(
        "File Access",
        "Cannot read Excel file",
        conditionMessage(e)
      )
      return(NULL)
    }
  )

  if (is.null(sheets)) return(result)

  # Required sheets for plots
  required_sheets <- c("DataCombined", "plotConfiguration")
  missing_sheets <- setdiff(required_sheets, sheets)

  if (length(missing_sheets) > 0) {
    result$add_critical_error(
      "Structure Error",
      sprintf("Required sheets missing: %s", paste(missing_sheets, collapse = ", ")),
      file_path
    )
    return(result)
  }

  # Read all sheets for validation
  all_data <- list()
  for (sheet in sheets) {
    sheet_data <- safe_execute({
      readxl::read_excel(file_path, sheet = sheet)
    })

    if (!is.null(sheet_data$result)) {
      all_data[[sheet]] <- sheet_data$result
    }

    for (error in sheet_data$errors) {
      result$add_critical_error(
        "File Access",
        sprintf("Cannot read sheet '%s': %s", sheet, error),
        sheet
      )
    }
  }

  # If we couldn't read required sheets, return
  if (!all(required_sheets %in% names(all_data))) {
    return(result)
  }

  # Validate DataCombined sheet
  validate_data_combined(all_data$DataCombined, result, scenarios_data, observed_data)

  # Validate plotConfiguration sheet
  validate_plot_configuration(all_data$plotConfiguration, all_data$DataCombined, result)

  # Validate plotGrids if present
  if ("plotGrids" %in% names(all_data)) {
    validate_plot_grids(all_data$plotGrids, all_data$plotConfiguration, result)
  }

  # Validate exportConfiguration if present
  if ("exportConfiguration" %in% names(all_data)) {
    validate_export_configuration(all_data$exportConfiguration, all_data$plotGrids, result)
  }

  # Store data if valid
  if (!result$has_critical_errors) {
    result$set_data(all_data)
  }

  return(result)
}

#' Helper: Validate DataCombined sheet
#' @keywords internal
validate_data_combined <- function(data, result, scenarios_data = NULL, observed_data = NULL) {
  # Check mandatory columns
  mandatory_cols <- c("DataCombinedName", "dataType", "label")
  missing_cols <- setdiff(mandatory_cols, names(data))

  if (length(missing_cols) > 0) {
    result$add_critical_error(
      "Missing Fields",
      sprintf("DataCombined missing mandatory columns: %s", paste(missing_cols, collapse = ", ")),
      "Sheet: DataCombined"
    )
    return()
  }

  # Check each row
  for (i in seq_len(nrow(data))) {
    row_data <- data[i, ]

    # Check mandatory fields not NA
    if (is.na(row_data$DataCombinedName)) {
      result$add_critical_error(
        "Missing Fields",
        sprintf("DataCombinedName is missing in row %d", i),
        "Sheet: DataCombined"
      )
    }

    if (is.na(row_data$dataType)) {
      result$add_critical_error(
        "Missing Fields",
        sprintf("dataType is missing in row %d", i),
        "Sheet: DataCombined"
      )
    }

    # Validate based on dataType
    if (!is.na(row_data$dataType)) {
      if (row_data$dataType == "simulated") {
        # Check scenario and path for simulated
        if (is.na(row_data$scenario)) {
          result$add_critical_error(
            "Missing Fields",
            sprintf("Scenario is required for simulated data in row %d", i),
            "Sheet: DataCombined"
          )
        }
        if (is.na(row_data$path)) {
          result$add_critical_error(
            "Missing Fields",
            sprintf("Path is required for simulated data in row %d", i),
            "Sheet: DataCombined"
          )
        }

        # Validate scenario exists if we have scenarios data
        if (!is.na(row_data$scenario) && !is.null(scenarios_data)) {
          if (!(row_data$scenario %in% scenarios_data$scenarios$Scenario_name)) {
            result$add_warning(
              "Invalid Reference",
              sprintf("Scenario '%s' does not exist in scenarios file (row %d)", row_data$scenario, i),
              "Sheet: DataCombined",
              recommendation = "Verify scenario name or add it to scenarios file"
            )
          }
        }

      } else if (row_data$dataType == "observed") {
        # Check dataSet for observed
        if (is.na(row_data$dataSet)) {
          result$add_critical_error(
            "Missing Fields",
            sprintf("DataSet is required for observed data in row %d", i),
            "Sheet: DataCombined"
          )
        }

        # Validate dataSet exists if we have observed data
        if (!is.na(row_data$dataSet) && !is.null(observed_data)) {
          if (!(row_data$dataSet %in% names(observed_data))) {
            result$add_warning(
              "Invalid Reference",
              sprintf("DataSet '%s' does not exist in observed data (row %d)", row_data$dataSet, i),
              "Sheet: DataCombined",
              recommendation = "Verify data set name or add it to data file"
            )
          }
        }
      } else {
        result$add_critical_error(
          "Format Error",
          sprintf("Invalid dataType '%s' in row %d (must be 'simulated' or 'observed')", row_data$dataType, i),
          "Sheet: DataCombined"
        )
      }
    }
  }

  # Check for duplicate DataCombinedNames
  duplicates <- data$DataCombinedName[duplicated(data$DataCombinedName) & !is.na(data$DataCombinedName)]
  if (length(duplicates) > 0) {
    result$add_critical_error(
      "Uniqueness Violation",
      sprintf("Duplicate DataCombinedNames found: %s", paste(unique(duplicates), collapse = ", ")),
      "Sheet: DataCombined"
    )
  }
}

#' Helper: Validate plotConfiguration sheet
#' @keywords internal
validate_plot_configuration <- function(data, data_combined, result) {
  # Check mandatory columns
  mandatory_cols <- c("plotID", "DataCombinedName", "plotType")
  missing_cols <- setdiff(mandatory_cols, names(data))

  if (length(missing_cols) > 0) {
    result$add_critical_error(
      "Missing Fields",
      sprintf("plotConfiguration missing mandatory columns: %s", paste(missing_cols, collapse = ", ")),
      "Sheet: plotConfiguration"
    )
    return()
  }

  # Valid plot types
  valid_plot_types <- c(
    "individual", "population", "observedVsSimulated",
    "residualVsSimulated", "residualsVsTime"
  )

  # Check each row
  for (i in seq_len(nrow(data))) {
    row_data <- data[i, ]

    # Check mandatory fields
    if (is.na(row_data$plotID)) {
      result$add_critical_error(
        "Missing Fields",
        sprintf("plotID is missing in row %d", i),
        "Sheet: plotConfiguration"
      )
    }

    if (is.na(row_data$DataCombinedName)) {
      result$add_critical_error(
        "Missing Fields",
        sprintf("DataCombinedName is missing in row %d", i),
        "Sheet: plotConfiguration"
      )
    }

    if (is.na(row_data$plotType)) {
      result$add_critical_error(
        "Missing Fields",
        sprintf("plotType is missing in row %d", i),
        "Sheet: plotConfiguration"
      )
    }

    # Validate plot type
    if (!is.na(row_data$plotType) && !(row_data$plotType %in% valid_plot_types)) {
      result$add_critical_error(
        "Format Error",
        sprintf("Invalid plotType '%s' in row %d", row_data$plotType, i),
        "Sheet: plotConfiguration"
      )
    }

    # Validate DataCombinedName reference
    if (!is.na(row_data$DataCombinedName)) {
      if (!is.null(data_combined) && !(row_data$DataCombinedName %in% data_combined$DataCombinedName)) {
        result$add_critical_error(
          "Invalid Reference",
          sprintf("DataCombinedName '%s' does not exist in DataCombined sheet (row %d)",
                  row_data$DataCombinedName, i),
          "Sheet: plotConfiguration"
        )
      }
    }
  }

  # Check for duplicate plotIDs
  duplicates <- data$plotID[duplicated(data$plotID) & !is.na(data$plotID)]
  if (length(duplicates) > 0) {
    result$add_critical_error(
      "Uniqueness Violation",
      sprintf("Duplicate plotIDs found: %s", paste(unique(duplicates), collapse = ", ")),
      "Sheet: plotConfiguration"
    )
  }
}

#' Helper: Validate plotGrids sheet
#' @keywords internal
validate_plot_grids <- function(data, plot_config, result) {
  if (is.null(data) || nrow(data) == 0) {
    result$add_warning(
      "Empty Data",
      "plotGrids sheet is empty",
      "Sheet: plotGrids",
      recommendation = "Add plot grids if you want to arrange multiple plots together"
    )
    return()
  }

  # Check mandatory columns
  mandatory_cols <- c("name", "plotIDs")
  missing_cols <- setdiff(mandatory_cols, names(data))

  if (length(missing_cols) > 0) {
    result$add_critical_error(
      "Missing Fields",
      sprintf("plotGrids missing mandatory columns: %s", paste(missing_cols, collapse = ", ")),
      "Sheet: plotGrids"
    )
    return()
  }

  # Check each row
  for (i in seq_len(nrow(data))) {
    row_data <- data[i, ]

    if (is.na(row_data$name)) {
      result$add_critical_error(
        "Missing Fields",
        sprintf("Plot grid name is missing in row %d", i),
        "Sheet: plotGrids"
      )
    }

    if (is.na(row_data$plotIDs)) {
      result$add_critical_error(
        "Missing Fields",
        sprintf("plotIDs are missing in row %d", i),
        "Sheet: plotGrids"
      )
    }

    # Validate plotID references
    if (!is.na(row_data$plotIDs) && !is.null(plot_config)) {
      plot_ids <- trimws(strsplit(as.character(row_data$plotIDs), ",")[[1]])
      invalid_ids <- setdiff(plot_ids, plot_config$plotID)

      if (length(invalid_ids) > 0) {
        result$add_warning(
          "Invalid Reference",
          sprintf("Invalid plotIDs in grid '%s': %s", row_data$name, paste(invalid_ids, collapse = ", ")),
          sprintf("Sheet: plotGrids, Row %d", i),
          recommendation = "Remove invalid plot IDs or add them to plotConfiguration"
        )
      }
    }
  }

  # Check for duplicate grid names
  duplicates <- data$name[duplicated(data$name) & !is.na(data$name)]
  if (length(duplicates) > 0) {
    result$add_critical_error(
      "Uniqueness Violation",
      sprintf("Duplicate plot grid names found: %s", paste(unique(duplicates), collapse = ", ")),
      "Sheet: plotGrids"
    )
  }
}

#' Helper: Validate exportConfiguration sheet
#' @keywords internal
validate_export_configuration <- function(data, plot_grids, result) {
  if (is.null(data) || nrow(data) == 0) {
    result$add_warning(
      "Empty Data",
      "exportConfiguration sheet is empty",
      "Sheet: exportConfiguration",
      recommendation = "Add export configurations to save plots to files"
    )
    return()
  }

  # Check for plotGridName column
  if (!("plotGridName" %in% names(data))) {
    result$add_warning(
      "Missing Fields",
      "exportConfiguration missing plotGridName column",
      "Sheet: exportConfiguration",
      recommendation = "Add plotGridName column to specify which grids to export"
    )
  }

  # Check each row
  for (i in seq_len(nrow(data))) {
    row_data <- data[i, ]

    # Check output file name
    if (!("outputFileName" %in% names(data)) || is.na(row_data$outputFileName)) {
      result$add_warning(
        "Missing Fields",
        sprintf("Output filename missing in row %d, will use default", i),
        "Sheet: exportConfiguration",
        recommendation = "Specify outputFileName for custom export names"
      )
    }

    # Validate plot grid references
    if ("plotGridName" %in% names(data) && !is.na(row_data$plotGridName)) {
      if (!is.null(plot_grids) && !(row_data$plotGridName %in% plot_grids$name)) {
        result$add_warning(
          "Invalid Reference",
          sprintf("Plot grid '%s' does not exist (row %d)", row_data$plotGridName, i),
          "Sheet: exportConfiguration",
          recommendation = "Verify plot grid name or add it to plotGrids sheet"
        )
      }
    }
  }
}

#' Validate All Configuration Files
#'
#' @description Validates all configuration files in a project
#' @param project_config Project configuration object or path
#' @return List of ValidationResult objects
#' @export
validate_all_configurations <- function(project_config) {
  # If path provided, load configuration first
  if (is.character(project_config)) {
    pc_validation <- validate_project_configuration(project_config)
    if (!pc_validation$is_valid()) {
      return(list(project_configuration = pc_validation))
    }
    project_config <- pc_validation$data
  }

  results <- list()

  # Validate project configuration
  results$project_configuration <- ValidationResult$new(
    project_config$path,
    "project_configuration"
  )
  results$project_configuration$set_data(project_config)

  # Validate each configuration file if it exists
  if (!is.na(project_config$scenariosFile) && file.exists(project_config$scenariosFile)) {
    results$scenarios <- validate_scenarios_file(project_config$scenariosFile, project_config)
  }

  if (!is.na(project_config$plotsFile) && file.exists(project_config$plotsFile)) {
    # Get scenarios and observed data for reference validation
    scenarios_data <- if (!is.null(results$scenarios)) results$scenarios$data else NULL
    observed_data <- NULL

    if (!is.na(project_config$dataFile) && file.exists(project_config$dataFile)) {
      observed_sheets <- safe_execute({
        sheets <- readxl::excel_sheets(project_config$dataFile)
        setdiff(sheets, "MetaInfo")
      })
      observed_data <- observed_sheets$result
    }

    results$plots <- validate_plots_file(
      project_config$plotsFile,
      scenarios_data,
      observed_data
    )
  }

  # Add more file validations as needed...

  return(results)
}

#' Print Validation Summary
#'
#' @description Prints a summary of all validation results
#' @param validation_results List of ValidationResult objects
#' @export
print_validation_summary <- function(validation_results) {
  cat("=================================================\n")
  cat("VALIDATION SUMMARY\n")
  cat("=================================================\n\n")

  total_critical <- 0
  total_warnings <- 0

  for (name in names(validation_results)) {
    result <- validation_results[[name]]
    if (!is.null(result)) {
      cat(sprintf("[ %s ]\n", toupper(gsub("_", " ", name))))
      cat(sprintf("  File: %s\n", result$file_path))

      if (result$has_critical_errors) {
        critical_count <- sum(sapply(result$critical_errors, length))
        total_critical <- total_critical + critical_count
        cat(sprintf("  ❌ Critical Errors: %d\n", critical_count))
      } else {
        cat("  ✅ No Critical Errors\n")
      }

      if (result$has_warnings) {
        warning_count <- sum(sapply(result$warnings, length))
        total_warnings <- total_warnings + warning_count
        cat(sprintf("  ⚠️ Warnings: %d\n", warning_count))
      } else {
        cat("  ✅ No Warnings\n")
      }
      cat("\n")
    }
  }

  cat("-------------------------------------------------\n")
  cat(sprintf("TOTAL: %d Critical Error(s), %d Warning(s)\n", total_critical, total_warnings))

  if (total_critical > 0) {
    cat("\n⛔ CANNOT PROCEED: Fix critical errors before importing.\n")
  } else if (total_warnings > 0) {
    cat("\n⚠️ CAN PROCEED: Review warnings for potential issues.\n")
  } else {
    cat("\n✅ ALL CLEAR: Configuration files are valid.\n")
  }
  cat("=================================================\n")
}