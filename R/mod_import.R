#' Format validation summary for modal display
#'
#' @param validation_summary Named vector or list from esqlabsR::validationSummary()
#' @return HTML-formatted string
#' @noRd
format_validation_summary <- function(validation_summary) {
  if (is.null(validation_summary) || length(validation_summary) == 0) {
    return("<p>No validation details available.</p>")
  }

  # If it's a named vector/list, format each element
  if (!is.null(names(validation_summary))) {
    html_parts <- lapply(names(validation_summary), function(name) {
      value <- validation_summary[[name]]

      # Format the label nicely
      label <- switch(name,
        "criticalErrorCount" = "Critical Errors",
        "warningCount" = "Warnings",
        "configFiles" = "Affected Configuration Files",
        "crossReferences" = "Cross-Reference Issues",
        gsub("([a-z])([A-Z])", "\\1 \\2", name)  # Default: split camelCase
      )

      # Format the value
      if (is.character(value) && length(value) > 1) {
        # Multiple items - show as list
        items <- paste0("<li>", value, "</li>", collapse = "")
        value_html <- paste0("<ul style='margin: 5px 0; padding-left: 20px;'>", items, "</ul>")
      } else if (is.numeric(value)) {
        # Numeric value with color coding
        color <- if (name %in% c("criticalErrorCount", "criticalErrors") && value > 0) {
          "color: #dc3545; font-weight: bold;"
        } else if (name %in% c("warningCount", "warnings") && value > 0) {
          "color: #ffc107; font-weight: bold;"
        } else {
          ""
        }
        value_html <- paste0("<span style='", color, "'>", value, "</span>")
      } else {
        value_html <- as.character(value)
      }

      paste0(
        "<div style='margin-bottom: 10px;'>",
        "<strong>", label, ":</strong> ", value_html,
        "</div>"
      )
    })

    return(paste(html_parts, collapse = ""))
  }

 # If it's a simple vector, join with line breaks
  return(paste0(
    "<div style='background: #f8f9fa; padding: 10px; border-radius: 4px;'>",
    "<pre style='margin: 0; white-space: pre-wrap;'>",
    paste(validation_summary, collapse = "\n"),
    "</pre>",
    "</div>"
  ))
}

#' import UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_import_ui <- function(id) {
  ns <- NS(id)
  tagList(
    shinyFiles::shinyFilesButton(
      ns("projectConfigurationFile"),
      "Select Project Configuration",
      "Please select the projectConfiguration excel file",
      multiple = FALSE
    )
  )
}

#' import Server Functions
#'
#' @noRd
mod_import_server <- function(id, r, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    volumes <- c(
      "Current Project" = getwd(),
      # "Test Project" = testthat::test_path("data"),
      Home = Sys.getenv("R_USER"),
      shinyFiles::getVolumes()()
    )

    shinyFiles::shinyFileChoose(input,
      id = "projectConfigurationFile",
      roots = volumes,
      filetypes = c("xlsx"),
      session = session
    )

    projectConfiguration <- reactive({
      req(input$projectConfigurationFile)
      projectConfigurationFilePath <- shinyFiles::parseFilePaths(
        volumes,
        input$projectConfigurationFile
      )
      req(projectConfigurationFilePath$datapath)

      # Clear previous validation results from old project (isolate to prevent reactive loop)
      isolate(r$warnings$clear_all())

      # Step 1 - Load project configuration
      project_config <- tryCatch(
        esqlabsR::createDefaultProjectConfiguration(path = projectConfigurationFilePath$datapath),
        error = function(e) {
          isolate({
            r$states$modal_message <- list(
              status = "Error Loading Project Configuration",
              message = conditionMessage(e)
            )
          })
          return(NULL)
        }
      )

      if (is.null(project_config)) return(NULL)

      # Step 2 - Validate all configurations using esqlabsR
      validation_results <- tryCatch(
        esqlabsR::validateAllConfigurations(project_config),
        error = function(e) {
          message("Validation error: ", conditionMessage(e))
          NULL
        }
      )

      # Process validation results if available
      if (!is.null(validation_results)) {
        # Check for critical errors
        has_critical <- esqlabsR::isAnyCriticalErrors(validation_results)

        # Get validation summary for display
        validation_summary <- esqlabsR::validationSummary(validation_results)

        # Store results in WarningHandler for display in mod_warning_modal (isolate to prevent reactive loop)
        isolate(r$warnings$add_esqlabsR_validation(validation_results, validation_summary))

        # If critical errors exist, show blocking modal and stop import
        if (has_critical) {
          # Format validation summary for display
          # validation_summary is a named vector/list from esqlabsR
          summary_html <- format_validation_summary(validation_summary)

          isolate({
            r$states$modal_message <- list(
              status = "Critical Validation Errors",
              message = HTML(paste0(
                "<div style='max-height: 500px; overflow-y: auto;'>",
                "<p><strong>The project configuration contains critical errors that must be fixed before importing.</strong></p>",
                "<hr>",
                summary_html,
                "<hr>",
                "<p style='color: #666; font-size: 0.9em;'>",
                "<i class='fa fa-info-circle'></i> Please fix the errors in your Excel files and try importing again.",
                "</p>",
                "</div>"
              ))
            )
          })
          return(NULL)
        }
      }

      # Return the project configuration
      project_config
    })

    # Import sheets from already-validated configuration files
    runAfterConfig <- function() {
      tryCatch(
        {
          config_map <- list(
            "scenarios"    = projectConfiguration()$scenariosFile,
            "individuals"  = projectConfiguration()$individualsFile,
            "populations"  = projectConfiguration()$populationsFile,
            "models"       = projectConfiguration()$modelParamsFile,
            "applications" = projectConfiguration()$applicationsFile,
            "plots"        = projectConfiguration()$plotsFile
          )

          # Import sheets from validated files
          for (config_file in r$data$get_config_files()) {
            r$data[[config_file]]$file_path <- config_map[[config_file]]

            if (!is.na(r$data[[config_file]]$file_path) && file.exists(r$data[[config_file]]$file_path)) {
              # Import sheets (no validation needed - already validated)
              sheet_names <- readxl::excel_sheets(r$data[[config_file]]$file_path)
              r$data[[config_file]]$sheets <- sheet_names
              for (sheet in sheet_names) {
                r$data$add_sheet(config_file, sheet, r$warnings)
              }
            }
          }

          # Populate dropdowns using configuration-driven approach
          dropdown_config <- get_dropdown_config()
          populate_dropdowns(DROPDOWNS, r$data, dropdown_config)

          # Handle special dropdown cases (named lists, etc.)
          populate_special_dropdowns(DROPDOWNS, r$data)
        },
        error = function(e) {
          message("Error in reading the project configuration file: ", conditionMessage(e))
          r$states$modal_message <- list(
            status  = "Error in reading the project configuration file",
            message = "File might be missing or not in the correct format. Please check the file and try again."
          )
          return(NULL)
        }
      )
    }

    # Modal flow: only if dataFile exists and has sheets
    observeEvent(projectConfiguration(), {
      pc <- projectConfiguration()
      # Make projectConfiguration path available across modules
      r$config$projectConfiguration <- pc
      # handle data file
      data_path <- pc$dataFile
      has_data_file <- isTruthy(data_path) && nzchar(data_path) && file.exists(data_path)
      # handle model folder
      model_folder_path <- pc$modelFolder
      has_model_folder <- isTruthy(model_folder_path) && nzchar(model_folder_path) && dir.exists(model_folder_path)

      if (has_data_file) {
        sheets <- tryCatch(readxl::excel_sheets(data_path), error = function(e) character(0))
        sheets <- setdiff(sheets, "MetaInfo")

        if (length(sheets) > 0) {
          r$observed_store$available  <- sheets
          r$observed_store$loaded  <- character(0)
        } else {
          r$observed_store$available  <- character(0)
          r$observed_store$loaded  <- character(0)
        }
      }

      if(has_model_folder) {
        pkml_paths <- list.files(
          model_folder_path,
          pattern = "\\.pkml$",
          full.names = TRUE,
          ignore.case = TRUE,
          recursive = FALSE
        )
        # get .pkml file names
        pkml_names <- basename(pkml_paths)
        DROPDOWNS$scenarios$model_files <- unique(pkml_names)
      }

      # if no data file or no sheets
      runAfterConfig()
    })

    # Share project configuration path with the export module
    return(projectConfiguration)
  })
}



## To be copied in the UI
# mod_import_ui("import_1")

## To be copied in the server
# mod_import_server("import_1")
