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
    # Dropzone with hidden native fileInput inside
    tags$div(
      class = "dropzone",
      id = ns("dropzone"),
      `data-input-id` = ns("projectEsqapp"),
      # Native Shiny fileInput (hidden via CSS)
      fileInput(
        ns("projectEsqapp"),
        label = NULL,
        accept = c(".esqapp", ".zip")
      ),
      # Visual elements
      tags$div(class = "dropzone-icon", icon("cloud-arrow-up")),
      tags$div(
        class = "dropzone-text",
        "Drag & drop your project here or ",
        tags$strong("browse")
      ),
      tags$div(class = "dropzone-hint", "Accepts .esqapp or .zip files"),
      # File info (shown after selection)
      tags$div(
        class = "dropzone-file-info",
        tags$div(class = "dropzone-file-name"),
        tags$div(class = "dropzone-file-size")
      )
    ),
    tags$script(src = "www/dropzone.js"),
    # Hidden input to track if project is loaded
    shinyjs::hidden(
      textInput(ns("projectLoaded"), label = NULL, value = "false")
    )
  )
}

#' import Server Functions
#'
#' @noRd
mod_import_server <- function(id, r, DROPDOWNS, METADATA) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Track pending file and confirmed file separately
    pending_file <- reactiveVal(NULL)
    confirmed_file <- reactiveVal(NULL)

    # Check if a project is currently loaded
    is_project_loaded <- reactive({
      !is.null(r$config$projectConfiguration)
    })

    # When file is selected, check if we need confirmation
    observeEvent(input$projectEsqapp, {
      req(input$projectEsqapp)

      if (is_project_loaded()) {
        # Store pending file and show confirmation modal
        pending_file(input$projectEsqapp)
        showModal(modalDialog(
          title = "Unsaved Changes",
          size = "l",
          tags$p("You have a project open. Loading a new project will discard any unsaved changes."),
          tags$p("Would you like to save your current project first?"),
          footer = tags$div(
            style = "display: flex; flex-direction: column; gap: 8px; width: 100%;",
            # Save dropdown button (reusable component)
            save_dropdown_ui(
              ns = ns,
              esqapp_id = "save_and_continue_esqapp",
              zip_id = "save_and_continue_zip",
              button_label = " Save & Continue",
              button_class = "btn btn-success dropdown-toggle",
              button_style = "width: 100%;",
              button_icon = icon("save")
            ),
            # Action buttons
            tags$div(
              style = "display: flex; gap: 8px; width: 100%;",
              actionButton(ns("confirm_load"), "Continue without saving", class = "btn-warning", style = "flex: 1;"),
              actionButton(ns("cancel_load"), "Cancel", style = "flex: 1;")
            )
          ),
          easyClose = FALSE
        ))
      } else {
        # No project loaded, proceed directly
        confirmed_file(input$projectEsqapp)
      }
    })

    # User confirms loading new project
    observeEvent(input$confirm_load, {
      removeModal()
      confirmed_file(pending_file())
      pending_file(NULL)
    })

    # User cancels loading
    observeEvent(input$cancel_load, {
      removeModal()
      pending_file(NULL)
    })

    # Helper function to get project name
    get_project_name <- function() {
      if (!is.null(r$config$projectConfiguration) &&
          !is.null(r$config$projectConfiguration$projectName)) {
        gsub("[^A-Za-z0-9_-]", "_", r$config$projectConfiguration$projectName)
      } else {
        "project"
      }
    }

    # Helper function to get project root
    get_project_root <- function() {
      config_path <- r$config$projectConfiguration
      if (!is.null(config_path) && !is.null(config_path$projectConfigurationFilePath)) {
        dirname(config_path$projectConfigurationFilePath)
      } else if (!is.null(r$config$project_root)) {
        r$config$project_root
      } else {
        NULL
      }
    }

    # Save as .esqapp & Continue
    output$save_and_continue_esqapp <- downloadHandler(
      filename = function() {
        paste0(get_project_name(), ".esqapp")
      },
      content = function(file) {
        original_project_root <- get_project_root()
        if (is.null(original_project_root)) {
          showNotification("Cannot determine project root directory", type = "error")
          return(NULL)
        }

        create_esqapp_shiny(
          original_project_root = original_project_root,
          r = r,
          output_file = file,
          DROPDOWN_COLUMN_TYPE_LIST = DROPDOWN_COLUMN_TYPE_LIST,
          NUMERIC_COLUMN_TYPE_LIST = NUMERIC_COLUMN_TYPE_LIST
        )

        removeModal()
        confirmed_file(pending_file())
        pending_file(NULL)
      }
    )

    # Save as .zip & Continue
    output$save_and_continue_zip <- downloadHandler(
      filename = function() {
        paste0(get_project_name(), ".zip")
      },
      content = function(file) {
        original_project_root <- get_project_root()
        if (is.null(original_project_root)) {
          showNotification("Cannot determine project root directory", type = "error")
          return(NULL)
        }

        create_esqapp_shiny(
          original_project_root = original_project_root,
          r = r,
          output_file = file,
          DROPDOWN_COLUMN_TYPE_LIST = DROPDOWN_COLUMN_TYPE_LIST,
          NUMERIC_COLUMN_TYPE_LIST = NUMERIC_COLUMN_TYPE_LIST
        )

        removeModal()
        confirmed_file(pending_file())
        pending_file(NULL)
      }
    )

    # Reactive for project configuration (only triggers when confirmed_file changes)
    projectConfiguration <- reactive({
      req(confirmed_file())
      load_esqapp_shiny(confirmed_file()$datapath, confirmed_file()$name, r)
    })

    # Load config + dropdown logic
    runAfterConfig <- function() {
      tryCatch(
        {
          # Reset all reactive values before loading new project
          r$data$reset()
          r$warnings$reset()
          r$observed_store <- reactiveValues(available = character(0), loaded = character(0))
          METADATA$plots$loaddata_metadata <- list()

          config_map <- list(
            "scenarios"    = projectConfiguration()$scenariosFile,
            "individuals"  = projectConfiguration()$individualsFile,
            "populations"  = projectConfiguration()$populationsFile,
            "models"       = projectConfiguration()$modelParamsFile,
            "applications" = projectConfiguration()$applicationsFile,
            "plots"        = projectConfiguration()$plotsFile
          )

          # Load all sheets first
          for (config_file in r$data$get_config_files()) {
            r$data[[config_file]]$file_path <- config_map[[config_file]]

            if (!is.na(r$data[[config_file]]$file_path) && file.exists(r$data[[config_file]]$file_path)) {
              sheet_names <- readxl::excel_sheets(r$data[[config_file]]$file_path)
              r$data[[config_file]]$sheets <- sheet_names
              for (sheet in sheet_names) {
                r$data$add_sheet(config_file, sheet, r$warnings)
              }
            }
          }

          # Populate dropdowns with new data
          DROPDOWNS$scenarios$individual_id       <- r$data$individuals$IndividualBiometrics$modified$IndividualId
          DROPDOWNS$scenarios$population_id       <- r$data$populations$Demographics$modified$PopulationName
          DROPDOWNS$scenarios$outputpath_id       <- r$data$scenarios$OutputPaths$modified$OutputPathId
          DROPDOWNS$scenarios$outputpath_id_alias <- setNames(
            as.list(as.character(r$data$scenarios$OutputPaths$modified$OutputPath)),
            r$data$scenarios$OutputPaths$modified$OutputPathId
          )
          DROPDOWNS$scenarios$model_parameters      <- unique(r$data$models$sheets)
          DROPDOWNS$plots$scenario_options          <- unique(r$data$scenarios$Scenarios$modified$Scenario_name)
          DROPDOWNS$plots$path_options              <- unique(r$data$scenarios$OutputPaths$modified$OutputPath)
          DROPDOWNS$plots$datacombinedname_options  <- unique(r$data$plots$DataCombined$modified$DataCombinedName)
          DROPDOWNS$plots$plotgridnames_options     <- unique(r$data$plots$plotGrids$modified$name)
          DROPDOWNS$plots$plotids_options           <- unique(r$data$plots$plotConfiguration$modified$plotID)
          DROPDOWNS$plots$datasets_options          <- c()
          DROPDOWNS$applications$application_protocols <- unique(r$data$applications$sheets)
        },
        error = function(e) {
          message("Error in reading the project configuration file: ", conditionMessage(e))
          showNotification(
            "Error reading configuration file. File might be missing or not in the correct format.",
            type = "error",
            duration = 10
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
