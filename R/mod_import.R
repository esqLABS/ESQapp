#' import UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
#' @importFrom shiny actionButton
#' @importFrom shiny icon
mod_import_ui <- function(id) {
  ns <- NS(id)
  tagList(
    shinyFiles::shinyFilesButton(
      ns("projectConfigurationFile"),
      "Select Project Configuration",
      "Please select the projectConfiguration excel file",
      multiple = FALSE
    ),
    actionButton(ns("reload_project"), "Reload Project")
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
      esqlabsR::createDefaultProjectConfiguration(
        path = projectConfigurationFilePath$datapath
      )
    })

    # Unchanged config + dropdown logic
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

          for (config_file in r$data$get_config_files()) {
            r$data[[config_file]]$file_path <- config_map[[config_file]]


            # Check if the file path is valid
            if (!is.na(r$data[[config_file]]$file_path) && file.exists(r$data[[config_file]]$file_path)) {
              sheet_names <- readxl::excel_sheets(r$data[[config_file]]$file_path)
              r$data[[config_file]]$sheets <- sheet_names
              for (sheet in sheet_names) {
                r$data$add_sheet(config_file, sheet, r$warnings)
              }
            }

            # Populate dropdowns
            DROPDOWNS$scenarios$individual_id       <- r$data$individuals$IndividualBiometrics$modified$IndividualId
            DROPDOWNS$scenarios$population_id       <- r$data$populations$Demographics$modified$PopulationName
            DROPDOWNS$scenarios$outputpath_id       <- r$data$scenarios$OutputPaths$modified$OutputPathId
            DROPDOWNS$scenarios$outputpath_id_alias <- setNames(
              as.list(as.character(r$data$scenarios$OutputPaths$modified$OutputPath)),
              r$data$scenarios$OutputPaths$modified$OutputPathId
            )
            DROPDOWNS$scenarios$model_parameters     <- unique(r$data$models$sheets)
            DROPDOWNS$plots$scenario_options        <- unique(r$data$scenarios$Scenarios$modified$Scenario_name)
            DROPDOWNS$plots$path_options            <- unique(r$data$scenarios$OutputPaths$modified$OutputPath)
            DROPDOWNS$plots$datacombinedname_options<- unique(r$data$plots$DataCombined$modified$DataCombinedName)
            DROPDOWNS$plots$plotgridnames_options   <- unique(r$data$plots$plotGrids$modified$name)
            DROPDOWNS$plots$plotids_options         <- unique(r$data$plots$plotConfiguration$modified$plotID)
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

    # Reload project function - re-reads all Excel files and resets modified data
    reloadProject <- function() {
      tryCatch(
        {
          # Check if project is loaded
          if (is.null(r$config$projectConfiguration)) {
            showNotification("No project loaded to reload.", type = "warning")
            return(FALSE)
          }

          # Get current file paths from project configuration
          config_map <- list(
            "scenarios"    = r$config$projectConfiguration$scenariosFile,
            "individuals"  = r$config$projectConfiguration$individualsFile,
            "populations"  = r$config$projectConfiguration$populationsFile,
            "models"       = r$config$projectConfiguration$modelParamsFile,
            "applications" = r$config$projectConfiguration$applicationsFile,
            "plots"        = r$config$projectConfiguration$plotsFile
          )

          # Clear warnings before reload
          r$warnings$warning_messages <- reactiveValues()

          # Re-read all files and reset modified data
          for (config_file in r$data$get_config_files()) {
            current_file_path <- config_map[[config_file]]
            
            # Skip if no file path or file doesn't exist
            if (is.na(current_file_path) || !file.exists(current_file_path)) {
              next
            }

            # Store current sheets for this config file
            current_sheets <- r$data[[config_file]]$sheets
            
            # Re-read all sheets
            sheet_names <- readxl::excel_sheets(current_file_path)
            r$data[[config_file]]$sheets <- sheet_names
            
            for (sheet in sheet_names) {
              # Remove existing sheet data if it exists
              if (!is.null(r$data[[config_file]][[sheet]])) {
                r$data[[config_file]][[sheet]] <- NULL
              }
              
              # Re-add the sheet (this will load fresh data)
              r$data$add_sheet(config_file, sheet, r$warnings)
            }
          }

          # Update dropdowns with fresh data
          runAfterConfig()

          # Trigger UI refresh to update the tables
          r$ui_triggers$selected_sheet <- runif(1)

          showNotification("Project reloaded successfully!", type = "message")
          return(TRUE)
        },
        error = function(e) {
          message("Error reloading project: ", conditionMessage(e))
          showNotification("Failed to reload project. Please check files and try again.", type = "error")
          return(FALSE)
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

    # Show confirmation modal when reload button is clicked
    observeEvent(input$reload_project, {
      showModal(
        modalDialog(
          title = "Reload Project",
          "Your changes will be lost, are you sure?",
          footer = tagList(
            actionButton(ns("confirm_reload"), "Yes"),
            modalButton("No")
          )
        )
      )
    })

    # Handle reload confirmation
    observeEvent(input$confirm_reload, {
      removeModal()
      reloadProject()
    })

    # Share project configuration path with the export module
    return(projectConfiguration)
  })
}



## To be copied in the UI
# mod_import_ui("import_1")

## To be copied in the server
# mod_import_server("import_1")
