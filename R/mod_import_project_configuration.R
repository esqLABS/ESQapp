#' import_project_configuration UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_import_project_configuration_ui <- function(id){
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

#' import_project_configuration Server Functions
#'
#' @noRd
mod_import_project_configuration_server <- function(id, r){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    r$imported_data <- reactiveValues()

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


      # Scenarios
      r$imported_data$scenarios$df <-
        rio::import(projectConfiguration()$scenarioDefinitionFile)
      r$imported_data$scenarios$output_paths <-
        rio::import(projectConfiguration()$scenarioDefinitionFile, sheet = 2)

      # Individuals
      r$imported_data$individuals$df <-
        rio::import(projectConfiguration()$individualsFile)
      r$imported_data$individuals$parameters <-
        rio::import(projectConfiguration()$individualsFile, sheet = 2)

      # Population
      r$imported_data$populations$df <-
        rio::import(projectConfiguration()$populationParamsFile)
      r$imported_data$populations$parameters <-
        rio::import(projectConfiguration()$populationParamsFile, sheet = 2)

      # NOTE: Application excel file is empty
      # # Application
      # r$imported_data$application$df <-
      #   rio::import(projectConfiguration()$scenarioApplicationsFile)

      # Model
      r$imported_data$models$df <-
        rio::import(projectConfiguration()$paramsFile)


      r$states$projectConfigurationLoaded <- TRUE
    })

    output$selected_file_path <- renderUI({
      req(projectConfiguration())

      verbatimTextOutput(ns("selected_file_path_text"))

    })

    output$selected_file_path_text <- renderPrint({
      req(projectConfiguration())
      projectConfiguration()$projectConfigurationFilePath
    })

  })
}

## To be copied in the UI
# mod_import_project_configuration_ui("import_project_configuration_1")

## To be copied in the server
# mod_import_project_configuration_server("import_project_configuration_1")
