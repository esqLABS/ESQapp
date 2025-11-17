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

      # Clear previous validation results
      r$warnings$clear_all()

      # Validate project configuration first
      pc_validation <- validate_project_configuration(projectConfigurationFilePath$datapath)
      r$warnings$add_validation_result("project_configuration", pc_validation)

      if (pc_validation$has_critical_errors) {
        # Show critical error modal
        showModal(
          modalDialog(
            title = "Critical Validation Errors",
            HTML(paste0(
              "<h4>Cannot import project configuration due to critical errors:</h4>",
              "<ul>",
              paste0("<li>", pc_validation$get_formatted_messages("critical"), "</li>", collapse = ""),
              "</ul>",
              "<p>Please fix these errors and try again.</p>"
            )),
            easyClose = TRUE,
            footer = modalButton("Close")
          )
        )
        return(NULL)
      }

      # Return the valid project configuration
      pc_validation$data
    })

    # Enhanced config + dropdown logic with validation
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

          # Track overall validation status
          has_any_critical_errors <- FALSE

          # Validate and import each configuration file
          for (config_file in r$data$get_config_files()) {
            r$data[[config_file]]$file_path <- config_map[[config_file]]

            # Check if the file path is valid
            if (!is.na(r$data[[config_file]]$file_path) && file.exists(r$data[[config_file]]$file_path)) {
              # Run appropriate validation based on file type
              validation_result <- NULL

              if (config_file == "scenarios") {
                validation_result <- validate_scenarios_file(r$data[[config_file]]$file_path, projectConfiguration())
                r$warnings$add_validation_result(config_file, validation_result)
              } else if (config_file == "plots") {
                # Get scenarios data for reference validation
                scenarios_data <- NULL
                if (!is.null(r$warnings$validation_results[["scenarios"]])) {
                  scenarios_data <- r$warnings$validation_results[["scenarios"]]$data
                }
                validation_result <- validate_plots_file(r$data[[config_file]]$file_path, scenarios_data, NULL)
                r$warnings$add_validation_result(config_file, validation_result)
              }
              # Add more validations for other file types as needed...

              # Check for critical errors
              if (!is.null(validation_result) && validation_result$has_critical_errors) {
                has_any_critical_errors <- TRUE
                # Skip importing this file due to critical errors
                message(sprintf("Skipping %s due to critical validation errors", config_file))
              } else {
                # Import sheets if no critical errors
                sheet_names <- readxl::excel_sheets(r$data[[config_file]]$file_path)
                r$data[[config_file]]$sheets <- sheet_names
                for (sheet in sheet_names) {
                  r$data$add_sheet(config_file, sheet, r$warnings)
                }
              }
            }
          }

          # Show critical errors modal if any exist
          if (has_any_critical_errors) {
            summary <- r$warnings$get_summary()
            showModal(
              modalDialog(
                title = "Validation Results - Critical Errors Found",
                HTML(paste0(
                  "<h4>Some files have critical errors and were not imported:</h4>",
                  "<p>Total critical errors: ", summary$total_critical_errors, "</p>",
                  "<p>Total warnings: ", summary$total_warnings, "</p>",
                  "<p>Affected files: ", paste(summary$affected_files, collapse = ", "), "</p>",
                  "<br>",
                  "<p>Click the warning icon in the navigation bar for details.</p>"
                )),
                easyClose = TRUE,
                footer = modalButton("Close")
              )
            )
          }

          # Only populate dropdowns if data was successfully imported
          if (file.exists(r$data$individuals$file_path) && !is.null(r$data$individuals$IndividualBiometrics)) {
            DROPDOWNS$scenarios$individual_id <- r$data$individuals$IndividualBiometrics$modified$IndividualId
          }
          if (file.exists(r$data$populations$file_path) && !is.null(r$data$populations$Demographics)) {
            DROPDOWNS$scenarios$population_id <- r$data$populations$Demographics$modified$PopulationName
          }
          if (file.exists(r$data$scenarios$file_path)) {
            if (!is.null(r$data$scenarios$OutputPaths)) {
              DROPDOWNS$scenarios$outputpath_id <- r$data$scenarios$OutputPaths$modified$OutputPathId
              DROPDOWNS$scenarios$outputpath_id_alias <- setNames(
                as.list(as.character(r$data$scenarios$OutputPaths$modified$OutputPath)),
                r$data$scenarios$OutputPaths$modified$OutputPathId
              )
              DROPDOWNS$plots$path_options <- unique(r$data$scenarios$OutputPaths$modified$OutputPath)
            }
            if (!is.null(r$data$scenarios$Scenarios)) {
              DROPDOWNS$plots$scenario_options <- unique(r$data$scenarios$Scenarios$modified$Scenario_name)
            }
          }
          if (file.exists(r$data$models$file_path)) {
            DROPDOWNS$scenarios$model_parameters <- unique(r$data$models$sheets)
          }
          if (file.exists(r$data$plots$file_path)) {
            if (!is.null(r$data$plots$DataCombined)) {
              DROPDOWNS$plots$datacombinedname_options <- unique(r$data$plots$DataCombined$modified$DataCombinedName)
            }
            if (!is.null(r$data$plots$plotGrids)) {
              DROPDOWNS$plots$plotgridnames_options <- unique(r$data$plots$plotGrids$modified$name)
            }
            if (!is.null(r$data$plots$plotConfiguration)) {
              DROPDOWNS$plots$plotids_options <- unique(r$data$plots$plotConfiguration$modified$plotID)
            }
          }
          if (file.exists(r$data$applications$file_path)) {
            DROPDOWNS$applications$application_protocols <- unique(r$data$applications$sheets)
          }
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
