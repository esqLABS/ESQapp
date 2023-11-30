#' application_data UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_application_data_ui <- function(id) {
  ns <- NS(id)
  tagList()
}

#' application_data Server Functions
#'
#' @noRd
mod_application_data_server <- function(id, r) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    r$states <- reactiveValues()

    r$data <- app_data(r)
  })
}

## To be copied in the UI
# mod_application_data_ui("application_data_1")

## To be copied in the server
# mod_application_data_server("application_data_1")

osp_units <- unique(unlist(ospsuite::ospUnits, use.names = F))

osp_units_time <- ospsuite::getUnitsForDimension("Time")

osp_species <- unlist(ospsuite::Species)


app_data <- function(r) {
  reactiveValues(
    "scenarios" = reactiveValues(
      file_path = NA,
      sheets = NA,
      "Scenarios" = reactiveValues(
        columns = reactiveValues(
          "Scenario_name" = list(type = "character"),
          "IndividualId" = list(
            type = "factor",
            reactive_levels = reactive({
              req(r$data$individuals$IndividualBiometrics$df$modified)
              r$data$individuals$IndividualBiometrics$df$modified$IndividualId
            })
          ),
          "PopulationId" = list(
            type = "factor",
            reactive_levels = reactive({
              req(r$data$populations$Demographics$df$modified$PopulationName)
              r$data$populations$Demographics$df$modified$PopulationName
            })
          ),
          "ReadPopulationFromCSV" = list(type = "factor"),
          "ModelParameterSheets" = list(type = "factor"),
          "ApplicationProtocol" = list(type = "factor"),
          "SimulationTime" = list(type = "list"),
          "SimulationTimeUnit" = list(
            type = "factor",
            fixed_levels = osp_units_time
          ),
          "SteadyState" = list(type = "logical"),
          "SteadyStateTime" = list(type = "numeric"),
          "SteadyStateTimeUnit" = list(
            type = "factor",
            fixed_levels = osp_units_time
          ),
          "ModelFile" = list(type = "factor"),
          "OutputPathsIds" = list(type = "list")
        ),
        df = reactiveValues()
      ),
      "OutputPaths" = reactiveValues(
        columns = reactiveValues(
          "OutputPathId" = list(type = "character"),
          "OutputPath" = list(type = "character")
        ),
        df = reactiveValues()
      )
    ),
    "individuals" = reactiveValues(
      file_path = NA,
      sheets = NA,
      "IndividualBiometrics" = reactiveValues(
        columns = reactiveValues(
          "IndividualId" = list(type = "character"),
          "Species" = list(
            type = "factor",
            fixed_levels = osp_species
          ),
          "Population" = list(type = "factor"),
          "Gender" = list(
            type = "factor",
            fixed_levels = c("MALE", "FEMALE")
          ),
          "Weight [kg]" = list(type = "numeric"),
          "Height [cm]" = list(type = "numeric"),
          "Age [year(s)]" = list(type = "numeric")
        ),
        df = reactiveValues()
      ),
      "Generic" = list(
        "Container Path" = list(type = "character"),
        "Parameter Name" = list(type = "character"),
        "Value" = list(type = "numeric"),
        "Units" = list(
          type = "factor",
          fixed_levels = osp_units
        )
      )
    ),
    "populations" = reactiveValues(
      file_path = NA,
      sheets = NA,
      "Demographics" = reactiveValues(
        columns = reactiveValues(
          "PopulationName" = list(type = "character"),
          "species" = list(
            type = "factor",
            fixed_levels = ospsuite::Species
          ),
          "population" = list(type = "factor"),
          "numberOfIndividuals" = list(type = "numeric"),
          "proportionOfFemales" = list(type = "numeric"),
          "weightMin" = list(type = "numeric"),
          "weightMax" = list(type = "numeric"),
          "weightUnit" = list(type = "factor"),
          "heightMin" = list(type = "numeric"),
          "heightMax" = list(type = "numeric"),
          "heightUnit" = list(type = "factor"),
          "ageMin" = list(type = "numeric"),
          "ageMax" = list(type = "numeric"),
          "BMIMin" = list(type = "numeric"),
          "BMIMax" = list(type = "numeric"),
          "BMIUnit" = list(type = "factor")
        ),
        df = reactiveValues()
      ),
      "UserDefinedVariability" = reactiveValues(
        columns = reactiveValues(
          "Container Path" = list(type = "character"),
          "Parameter Name" = list(type = "character"),
          "Mean" = list(type = "numeric"),
          "SD" = list(type = "numeric"),
          "Distribution" = list(type = "factor")
        ),
        df = reactiveValues()
      )
    ),
    "models" = reactiveValues(
      file_path = NA,
      sheets = NA,
      "Global" = reactiveValues(
        columns = reactiveValues(
          "Container Path" = list(type = "character"),
          "Parameter Name" = list(type = "character"),
          "Value" = list(type = "numeric"),
          "Units" = list(
            type = "factor",
            fixed_levels = osp_units
          )
        ),
        df = reactiveValues()
      )
    )
  )
}
