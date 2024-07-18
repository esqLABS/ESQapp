#' simulationtime_module UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_simulationtime_module_ui <- function(id){
  ns <- NS(id)
  tagList()
}

#' simulationtime_module Server Functions
#'
#' @noRd
mod_simulationtime_module_server <- function(id){
  moduleServer( id, function(input, output, session) {
    ns <- session$ns

    # input$process_simulation_time_conversion comes from esqlabs.handsontable |>
    # utils/simulationTimeModal.js |>
    # function sendSimulationTimeModalDataToShinyAndAwaitResponse
    observeEvent(input$process_simulation_time_conversion, {

      json_data_parsed_js <- jsonlite::fromJSON(
        input$process_simulation_time_conversion,
        simplifyVector = FALSE
      )
      simulation_time_list_res <- .createOutputSchemaStringFromJson(
        outputSchemaJson = json_data_parsed_js$jsonSchema,
        schemaUnit       = json_data_parsed_js$timeUnit
      )

      session$sendCustomMessage(
        "shinyResponse",
        simulation_time_list_res$Intervals
      )

    })

  })
}

## To be copied in the UI
# mod_simulationtime_module_ui("simulationtime_module_1")

## To be copied in the server
# mod_simulationtime_module_server("simulationtime_module_1")
