columns_data <- list(
  "scenarios" = list(
    "Scenarios" = list(
      "Scenario_name" = list(type = "character"),
      "IndividualId" = list(
        type = "factor",
        reactive_levels = "r$data$individuals$IndividualBiometrics$modified$IndividualId"
      ),
      "PopulationId" = list(
        type = "factor",
        reactive_levels = "r$data$populations$Demographics$modified$PopulationName"
      ),
      "ReadPopulationFromCSV" = list(type = "factor"),
      "ModelParameterSheets" = list(type = "factor"),
      "ApplicationProtocol" = list(type = "factor"),
      "SimulationTime" = list(type = "list"),
      "SimulationTimeUnit" = list(
        type = "factor",
        fixed_levels = ospsuite::getUnitsForDimension("Time")
      ),
      "SteadyState" = list(type = "logical"),
      "SteadyStateTime" = list(type = "numeric"),
      "SteadyStateTimeUnit" = list(
        type = "factor",
        fixed_levels = ospsuite::getUnitsForDimension("Time")
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
        fixed_levels = unlist(ospsuite::Species)
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
      "Units" = list(type = "factor",
                     fixed_levels = unique(unlist(ospsuite::ospUnits,use.names = F)))
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
      "Units" = list(type = "factor",
                     fixed_levels =  unique(unlist(ospsuite::ospUnits,use.names = F)))
    )
  )
)



type_columns <- function(df, config_file, sheet) {
  types <- columns_data[[config_file]][[sheet]]

  if (is.null(types)) {
    types <- columns_data[[config_file]][["Generic"]]
  }

  columns <- colnames(df)

  for (column in columns) {
    column_info <- types[[column]]

    if (!is.null(column_info$type)) {
      df[[column]] <- switch(column_info$type,
        "character" = df[[column]],
        "list" = df[[column]],
        "numeric" = as.numeric(df[[column]]),
        "logical" = as.logical(df[[column]]),
        "factor" = add_fixed_factor_levels(df[[column]], column_info)
      )
    }
  }

  return(df)
}

add_fixed_factor_levels <- function(column, column_info) {
  if (!is.null(column_info$fixed_levels)) {
    column <- factor(column, levels = column_info$fixed_levels)
  } else {
    column <- as.factor(column)
  }

  return(column)
}
