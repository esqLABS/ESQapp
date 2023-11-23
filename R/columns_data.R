osp_units <- unique(unlist(ospsuite::ospUnits, use.names = F))

osp_units_time <- ospsuite::getUnitsForDimension("Time")

osp_species <- unlist(ospsuite::Species)


columns_data <- function(r) {
  list(
    "scenarios" = list(
      "Scenarios" = list(
        "Scenario_name" = list(type = "character"),
        "IndividualId" = list(
          type = "factor",
          reactive_levels = reactive({
            req(r$data$individuals$IndividualBiometrics$modified)
            r$data$individuals$IndividualBiometrics$modified$IndividualId
          })
        ),
        "PopulationId" = list(
          type = "factor",
          reactive_levels = reactive({
            req(r$data$populations$Demographics$modified$PopulationName)
            r$data$populations$Demographics$modified$PopulationName
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
      "OutputPaths" = list(
        "OutputPathId" = list(type = "character"),
        "OutputPath" = list(type = "character")
      )
    ),
    "individuals" = list(
      "IndividualBiometrics" = list(
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
    "populations" = list(
      "Demographics" = list(
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
      "UserDefinedVariability" = list(
        "Container Path" = list(type = "character"),
        "Parameter Name" = list(type = "character"),
        "Mean" = list(type = "numeric"),
        "SD" = list(type = "numeric"),
        "Distribution" = list(type = "factor")
      )
    ),
    "models" = list(
      "Global" = list(
        "Container Path" = list(type = "character"),
        "Parameter Name" = list(type = "character"),
        "Value" = list(type = "numeric"),
        "Units" = list(
          type = "factor",
          fixed_levels = osp_units
        )
      )
    )
  )
}
