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
    # Modern file input card
    bslib::card(
      height = "auto",
      style = "border: 2px dashed #007bff; margin-bottom: 15px;",
      bslib::card_body(
        class = "text-center p-4",
        
        # File input
        fileInput(
          ns("projectConfigurationFile"),
          label = NULL,
          accept = ".xlsx,.xls",
          buttonLabel = "Browse Files",
          placeholder = "No file selected",
          width = "100%"
        ),
        
        # Visual enhancement with icon and instructions
        div(
          style = "margin-top: 15px;",
          tags$div(
            style = "font-size: 2.5rem; color: #007bff; margin-bottom: 10px;",
            "📁" # Using emoji as fallback for icon
          ),
          tags$h6(
            "Project Configuration File", 
            style = "margin: 10px 0 5px 0; color: #495057; font-weight: 600;"
          ),
          tags$small(
            "Select an Excel file (.xlsx, .xls)", 
            style = "color: #6c757d; display: block; margin-bottom: 5px;"
          ),
          tags$small(
            "Drag and drop supported", 
            style = "color: #28a745; font-style: italic;"
          )
        )
      )
    ),
    
    # File path display
    uiOutput(ns("selected_file_path"))
  )
}

#' import Server Functions
#'
#' @noRd
mod_import_server <- function(id, r, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    projectConfiguration <- reactive({
      req(input$projectConfigurationFile)
      
      # Get the uploaded file info
      file_info <- input$projectConfigurationFile
      req(file_info$datapath)
      
      # Validate file extension
      file_ext <- tools::file_ext(file_info$name)
      if (!file_ext %in% c("xlsx", "xls")) {
        showNotification(
          "Please select an Excel file (.xlsx or .xls)",
          type = "error",
          duration = 5
        )
        return(NULL)
      }

      esqlabsR::createDefaultProjectConfiguration(path = file_info$datapath)
    })

    observeEvent(projectConfiguration(), {

      tryCatch(
        {
          config_map <- list(
            "scenarios" = projectConfiguration()$scenariosFile,
            "individuals" = projectConfiguration()$individualsFile,
            "populations" = projectConfiguration()$populationsFile,
            "models" = projectConfiguration()$modelParamsFile,
            "applications" = projectConfiguration()$applicationsFile,
            "plots" = projectConfiguration()$plotsFile
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
            DROPDOWNS$scenarios$individual_id <- r$data$individuals$IndividualBiometrics$modified$IndividualId
            DROPDOWNS$scenarios$population_id <- r$data$populations$Demographics$modified$PopulationName
            DROPDOWNS$scenarios$outputpath_id <- r$data$scenarios$OutputPaths$modified$OutputPathId
            DROPDOWNS$scenarios$model_parameters <- r$data$models$sheets |> unique()
            DROPDOWNS$plots$scenario_options <- r$data$scenarios$Scenarios$modified$Scenario_name |> unique()
            DROPDOWNS$plots$path_options <- r$data$scenarios$OutputPaths$modified$OutputPath |> unique()
            DROPDOWNS$plots$datacombinedname_options <- r$data$plots$DataCombined$modified$DataCombinedName |> unique()
            DROPDOWNS$plots$plotgridnames_options <- r$data$plots$plotGrids$modified$name |> unique()
            DROPDOWNS$plots$plotids_options <- r$data$plots$plotConfiguration$modified$plotID |> unique()
            DROPDOWNS$applications$application_protocols <- r$data$applications$sheets |> unique()
          }
        },
        error = function(e) {
          return(NULL)
          message("Error in reading the project configuration file")
          r$states$modal_message <- list(
            status = "Error in reading the project configuration file",
            message = paste0(
              "File might be missing or not in the correct format. Please check the file and try again.",
            )
          )

        }
      )
    })

    output$selected_file_path <- renderUI({
      req(input$projectConfigurationFile)
      
      file_info <- input$projectConfigurationFile
      
      # Create a nice display for the selected file
      bslib::card(
        style = "margin-top: 10px; border-left: 4px solid #28a745;",
        bslib::card_body(
          style = "padding: 10px 15px;",
          div(
            style = "display: flex; align-items: center;",
            span(
              style = "color: #28a745; margin-right: 8px; font-size: 1.2em;",
              "✓"
            ),
            div(
              tags$strong("Selected File:", style = "color: #495057;"),
              br(),
              tags$small(file_info$name, style = "color: #6c757d;"),
              br(),
              tags$small(
                paste("Size:", round(file_info$size / 1024, 1), "KB"), 
                style = "color: #6c757d;"
              )
            )
          )
        )
      )
    })

    output$selected_file_path_text <- renderPrint({
      req(input$projectConfigurationFile)
      input$projectConfigurationFile$name
    })

    # Share project configuration path with the export module
    return(projectConfiguration)
  })
}



## To be copied in the UI
# mod_import_ui("import_1")

## To be copied in the server
# mod_import_server("import_1")
