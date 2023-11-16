column_types <- list(
  "scenarios" = list(
    "Scenarios" = list(
      "Scenario_name" = "character",
      "IndividualId" = "factor",
      "PopulationId" = "factor",
      "ReadPopulationFromCSV" = "factor",
      "ModelParameterSheets" = "factor",
      "ApplicationProtocol" = "factor",
      "SimulationTime" = "list",
      "SimulationTimeUnit" = "factor",
      "SteadyState" = "logical",
      "SteadyStateTime" = "numeric",
      "SteadyStateTimeUnit" = "factor",
      "ModelFile" = "factor",
      "OutputPathsIds" = "list"
    ),
    "OutputPaths" = list(
      "OutputPathId" = "character",
      "OutputPath" = "character"
    )
  ),
  "individuals" = list(
    "IndividualBiometrics" = list(
      "IndividualId" = "character",
      "Species" = "factor",
      "Population" = "factor",
      "Gender" = "factor",
      "Weight [kg]" = "numeric",
      "Height [cm]" = "numeric",
      "Age [year(s)]" = "numeric"
    ),
    "Generic" = list(
      "Container Path" = "character",
      "Parameter Name" = "character",
      "Value" = "numeric",
      "Units" = "factor"
    )
  ),
  "populations" = list(
    "Demographics" = list(
      "PopulationName" = "character",
      "species" = "factor",
      "population" = "factor",
      "numberOfIndividuals" = "numeric",
      "proportionOfFemales" = "numeric",
      "weightMin" = "numeric",
      "weightMax" = "numeric",
      "weightUnit" = "factor",
      "heightMin" = "numeric",
      "heightMax" = "numeric",
      "heightUnit" = "factor",
      "ageMin" = "numeric",
      "ageMax" = "numeric",
      "BMIMin" = "numeric",
      "BMIMax" = "numeric",
      "BMIUnit" = "factor"
    ),
    "UserDefinedVariability" = list(
      "Container Path" = "character",
      "Parameter Name" = "character",
      "Mean" = "numeric",
      "SD" = "numeric",
      "Distribution" = "factor"
    )
  ),
  "models" = list(
    "Global" = list(
      "Container Path" = "character",
      "Parameter Name" = "character",
      "Value" = "numeric",
      "Units" = "factor"
    )
  )
)


type_columns <- function(df, config_file, sheet) {

  types <- column_types[[config_file]][[sheet]]

  if (is.null(types)) {
    types <- column_types[[config_file]][["Generic"]]
  }

  columns <- colnames(df)

  for (column in columns) {
    column_type <- types[[column]]

    if (!is.null(column_type)) {
      df[[column]] <- switch(column_type,
        "character" = df[[column]],
        "list" = df[[column]],
        "numeric" = as.numeric(df[[column]]),
        "logical" = as.logical(df[[column]]),
        "factor" = as.factor(df[[column]])
      )
    }
  }

  return(df)
}
