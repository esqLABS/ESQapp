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
      "Please select the projectConfiguration file (JSON or Excel)",
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
      filetypes = c("json", "xlsx"),
      session = session
    )

    # Track if we're using JSON or Excel
    config_file_type <- reactiveVal(NULL)

    projectConfiguration <- reactive({
      req(input$projectConfigurationFile)
      projectConfigurationFilePath <- shinyFiles::parseFilePaths(
        volumes,
        input$projectConfigurationFile
      )
      req(projectConfigurationFilePath$datapath)

      file_path <- projectConfigurationFilePath$datapath
      file_ext <- tolower(tools::file_ext(file_path))

      # Determine file type and load accordingly
      if (file_ext == "json") {
        config_file_type("json")
        # Return a list with similar structure to esqlabsR config for compatibility
        load_json_project_configuration(file_path)
      } else {
        config_file_type("xlsx")
        esqlabsR::createDefaultProjectConfiguration(
          path = file_path
        )
      }
    })

    # Config + dropdown logic - supports both JSON and Excel
    runAfterConfig <- function() {
      tryCatch(
        {
          pc <- projectConfiguration()
          file_type <- config_file_type()

          if (file_type == "json") {
            # JSON-based loading
            runAfterConfigJSON(pc)
          } else {
            # Excel-based loading (original behavior)
            runAfterConfigExcel(pc)
          }

          # Populate dropdowns (common for both JSON and Excel)
          populateDropdowns()
        },
        error = function(e) {
          message("Error in reading the project configuration file: ", conditionMessage(e))
          r$states$modal_message <- list(
            status  = "Error in reading the project configuration file",
            message = sprintf("File might be missing or not in the correct format. Error: %s", conditionMessage(e))
          )
          return(NULL)
        }
      )
    }

    # JSON-based configuration loading
    runAfterConfigJSON <- function(pc) {
      json_config <- pc$json_config

      if (is.null(json_config)) {
        stop("JSON configuration not loaded properly")
      }

      # Check for errors
      if (json_config$has_errors()) {
        errors_df <- json_config$errors$as_data_frame()
        # Only stop on fatal errors (file not found, parse errors)
        fatal_errors <- errors_df[grepl("^E00[1-3]", errors_df$code), ]
        if (nrow(fatal_errors) > 0) {
          stop(paste(fatal_errors$message, collapse = "; "))
        }
      }

      # Add warnings from JSON validation
      if (json_config$has_warnings()) {
        for (w in json_config$warnings$items) {
          r$warnings$add_warning(
            config_file = tolower(w$section),
            sheet_name = w$sheet %||% "general",
            message = sprintf("[%s] %s", w$code, w$message)
          )
        }
      }

      # Add validation errors as warnings (non-fatal)
      if (json_config$has_errors()) {
        for (e in json_config$errors$items) {
          if (!grepl("^E00[1-3]", e$code)) {
            r$warnings$add_warning(
              config_file = tolower(e$section),
              sheet_name = e$sheet %||% "general",
              message = sprintf("[%s] %s", e$code, e$message)
            )
          }
        }
      }

      # Map JSON sections to data structure
      section_map <- list(
        scenarios = json_config$scenarios,
        individuals = json_config$individuals,
        populations = json_config$populations,
        models = json_config$model_parameters,
        applications = json_config$applications,
        plots = json_config$plots
      )

      for (config_file in r$data$get_config_files()) {
        section_data <- section_map[[config_file]]

        if (!is.null(section_data) && length(section_data) > 0) {
          r$data[[config_file]]$file_path <- json_config$file_path
          r$data[[config_file]]$sheets <- names(section_data)

          for (sheet_name in names(section_data)) {
            df <- section_data[[sheet_name]]

            if (is.null(r$data[[config_file]][[sheet_name]])) {
              r$data[[config_file]][[sheet_name]] <- reactiveValues()
            }

            r$data[[config_file]][[sheet_name]]$original <- df
            r$data[[config_file]][[sheet_name]]$modified <- df
          }
        }
      }

      # Store JSON config reference for export
      r$config$json_config <- json_config
      r$config$config_type <- "json"
    }

    # Excel-based configuration loading (original behavior)
    runAfterConfigExcel <- function(pc) {
      config_map <- list(
        "scenarios"    = pc$scenariosFile,
        "individuals"  = pc$individualsFile,
        "populations"  = pc$populationsFile,
        "models"       = pc$modelParamsFile,
        "applications" = pc$applicationsFile,
        "plots"        = pc$plotsFile
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
      }

      r$config$config_type <- "xlsx"
    }

    # Populate dropdowns (shared logic)
    populateDropdowns <- function() {
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

    # Modal flow: only if dataFile exists and has sheets
    observeEvent(projectConfiguration(), {
      pc <- projectConfiguration()
      # Make projectConfiguration path available across modules
      r$config$projectConfiguration <- pc

      # Get paths - handle both JSON and Excel configurations
      file_type <- config_file_type()

      if (file_type == "json") {
        # For JSON, get resolved paths from json_config
        data_path <- pc$json_config$get_path("dataFile")
        model_folder_path <- pc$json_config$get_path("modelFolder")
      } else {
        # For Excel (esqlabsR), paths are already resolved
        data_path <- pc$dataFile
        model_folder_path <- pc$modelFolder
      }

      has_data_file <- isTruthy(data_path) && nzchar(data_path) && file.exists(data_path)
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


#' Load JSON project configuration
#'
#' @description Helper function to load a JSON project configuration file
#' and return a compatible structure for the import module
#'
#' @param file_path Path to the JSON configuration file
#' @return List with json_config and compatibility fields
#' @noRd
load_json_project_configuration <- function(file_path) {
  json_config <- ProjectConfigurationJSON$new(file_path)

  # Create a compatible structure that mimics esqlabsR's projectConfiguration
  # This allows the rest of the code to work with minimal changes
  list(
    json_config = json_config,
    # Compatibility fields for esqlabsR-style access
    modelFolder = json_config$get_path("modelFolder"),
    configurationsFolder = json_config$get_path("configurationsFolder"),
    dataFolder = json_config$get_path("dataFolder"),
    dataFile = json_config$get_path("dataFile"),
    outputFolder = json_config$get_path("outputFolder"),
    # These return the JSON file path since all data is in the JSON
    scenariosFile = json_config$file_path,
    individualsFile = json_config$file_path,
    populationsFile = json_config$file_path,
    modelParamsFile = json_config$file_path,
    applicationsFile = json_config$file_path,
    plotsFile = json_config$file_path
  )
}


## To be copied in the UI
# mod_import_ui("import_1")

## To be copied in the server
# mod_import_server("import_1")
