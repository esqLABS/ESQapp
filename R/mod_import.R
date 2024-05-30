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
      # "Current Project" = getwd(),
      "Test Project" = testthat::test_path("data"),
      Home = Sys.getenv("R_USER"),
      shinyFiles::getVolumes()()
    )

    shinyFiles::shinyFileChoose(input,
      id = "projectConfigurationFile",
      roots = volumes,
      session = session
    )


    projectConfiguration <- reactive({
      req(input$projectConfigurationFile)
      projectConfigurationFilePath <- shinyFiles::parseFilePaths(
        volumes,
        input$projectConfigurationFile
      )

      req(projectConfigurationFilePath$datapath)

      esqlabsR::createDefaultProjectConfiguration(path = projectConfigurationFilePath$datapath)
    })

    observeEvent(projectConfiguration(), {
      for (config_file in names(r$data)) {
        r$data[[config_file]]$file_path <-
          dplyr::case_match(
            config_file,
            "scenarios" ~ projectConfiguration()$scenarioDefinitionFile,
            "individuals" ~ projectConfiguration()$individualsFile,
            "populations" ~ projectConfiguration()$populationParamsFile,
            "models" ~ projectConfiguration()$paramsFile,
            "plots" ~ projectConfiguration()$plotsFile
          )

        sheet_names <- readxl::excel_sheets(r$data[[config_file]]$file_path)

        r$data[[config_file]]$sheets <- sheet_names

        for (sheet in sheet_names) {
          r$data[[config_file]][[sheet]] <- reactiveValues()

          r$data[[config_file]][[sheet]]$original <-
            rio::import(
              r$data[[config_file]]$file_path,
              sheet = sheet,
              col_types = "text"
            )

          # preassign modified data with original data
          r$data[[config_file]][[sheet]]$modified <- r$data[[config_file]][[sheet]]$original
        }

        # Populate dropdowns
        DROPDOWNS$scenarios$individual_id        <- r$data$individuals$IndividualBiometrics$modified$IndividualId
        DROPDOWNS$scenarios$population_id        <- r$data$populations$Demographics$modified$PopulationName
        DROPDOWNS$scenarios$outputpath_id        <- r$data$scenarios$OutputPaths$modified$OutputPathId
        DROPDOWNS$plots$scenario_options         <- r$data$scenarios$Scenarios$modified$Scenario_name |> unique()
        DROPDOWNS$plots$path_options             <- r$data$scenarios$OutputPaths$modified$OutputPath |> unique()
        DROPDOWNS$plots$datacombinedname_options <- r$data$plots$DataCombined$modified$DataCombinedName |> unique()
      }
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
