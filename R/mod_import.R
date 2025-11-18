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

      # Clear previous validation results from old project
      r$warnings$clear_all()

      # TODO: Step 1 - Load project configuration (esqlabsR)
      # This should stay simple - just load the project config
      project_config <- tryCatch(
        esqlabsR::createDefaultProjectConfiguration(path = projectConfigurationFilePath$datapath),
        error = function(e) {
          r$states$modal_message <- list(
            status = "Error Loading Project Configuration",
            message = conditionMessage(e)
          )
          return(NULL)
        }
      )

      if (is.null(project_config)) return(NULL)

      # TODO: Step 2 - Validate all configurations (esqlabsR should provide this)
      # esqlabsR should provide a single validation function:
      #   validation_results <- esqlabsR::validateAllConfigurations(project_config)
      #
      # This function should:
      # - Validate project configuration itself
      # - Validate all referenced files (scenarios, plots, individuals, populations, models, applications)
      # - Check sheet presence (missing sheet = critical error)
      # - Check column names (missing columns = critical error)
      # - Check sheet content (empty sheet = warning, not critical error)
      # - Add default column names to empty sheets when applicable
      # - Validate cross-file references (e.g., plots referencing scenarios)
      # - Return ValidationResult object for each file with:
      #   * critical_errors: blocking issues (missing files, missing sheets, missing columns)
      #   * warnings: non-blocking issues (empty sheets, missing references, etc.)
      #   * data: the validated and loaded data (with default columns added if needed)

      # TEMPORARY: Until esqlabsR implements validation, just return project config
      # In future, this will be replaced with validation results

      # Store validation results (will be populated by esqlabsR in future)
      # r$warnings$add_validation_results(validation_results)
      #
      # Show critical errors immediately in a blocking modal
      # (Warnings will be shown via bell icon in mod_warning_modal.R)
      # if (r$warnings$has_critical_errors) {
      #   # Format critical errors for display
      #   error_details <- lapply(names(r$warnings$critical_errors), function(config_file) {
      #     errors <- r$warnings$critical_errors[[config_file]]
      #     paste0("<h5>File: ", config_file, "</h5><ul>",
      #            paste0("<li>", errors, "</li>", collapse = ""),
      #            "</ul>")
      #   })
      #
      #   r$states$modal_message <- list(
      #     status = "Critical Validation Errors",
      #     message = paste0(
      #       "<p><strong>The following critical errors must be fixed before importing:</strong></p>",
      #       paste(error_details, collapse = "")
      #     )
      #   )
      #   return(NULL)
      # }

      # Return the project configuration
      project_config
    })

    # Import sheets from already-validated configuration files
    runAfterConfig <- function() {
      tryCatch(
        {
          # TODO: This function should only import sheets, NOT do validation
          # Validation happens in projectConfiguration reactive above
          # This function is only called if projectConfiguration succeeded (no critical errors)

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
