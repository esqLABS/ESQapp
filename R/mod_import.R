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
    ),
    uiOutput(ns("selected_file_path"))
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

    # Modal flow: only if dataFile exists and has sheets
    observeEvent(projectConfiguration(), {
      pc <- projectConfiguration()
      data_path <- pc$dataFile
      has_data_file <- isTruthy(data_path) && nzchar(data_path) && file.exists(data_path)

      if (has_data_file) {
        sheets <- tryCatch(readxl::excel_sheets(data_path), error = function(e) character(0))
        sheets <- setdiff(sheets, "MetaInfo")

        if (length(sheets) > 0) {
          showModal(
            modalDialog(
              title = "Load observed data",
              tagList(
                p("Select the sheets to load from the observed data Excel file:"),
                checkboxGroupInput(
                  inputId = ns("selectedSheets"),
                  label   = NULL,
                  choices = sheets,
                  selected = NULL
                )
              ),
              footer = tagList(
                actionButton(ns("skip_load_data"), "Skip"),
                actionButton(ns("confirm_load_data"), "Load selected sheets")
              ),
              easyClose = FALSE
            )
          )


          observeEvent(input$confirm_load_data, ignoreInit = TRUE, once = TRUE, {
            removeModal()
            sel <- input$selectedSheets %||% character(0)
            if (length(sel) > 0) {
              # store in r$observed_data
              r$observed_data <- tryCatch(
                esqlabsR::loadObservedData(pc, sel),
                error = function(e) {
                  r$states$modal_message <- list(
                    status  = "Error loading observed data",
                    message = paste("Details:", conditionMessage(e))
                  )
                  NULL
                }
              )

              if (!is.null(r$observed_data)) {
                DROPDOWNS$plots$datasets_options <- unique(names(r$observed_data))
              }

            }
            runAfterConfig()
          })

          # --- Skip button: close modal but still load config
          observeEvent(input$skip_load_data, ignoreInit = TRUE, once = TRUE, {
            removeModal()
            runAfterConfig()
          })

          return(invisible(NULL))
        }
      }

      # if no data file or no sheets
      runAfterConfig()
    })

    output$selected_file_path <- renderUI({
      req(projectConfiguration())

      verbatimTextOutput(ns("selected_file_path_text"))
    })

    output$selected_file_path_text <- renderPrint({
      req(projectConfiguration())
      projectConfiguration()$projectConfigurationFilePath
    })

    # Share project configuration path with the export module
    return(projectConfiguration)
  })
}



## To be copied in the UI
# mod_import_ui("import_1")

## To be copied in the server
# mod_import_server("import_1")
