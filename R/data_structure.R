data_structure <- function() {
  list(
    "scenarios" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "individuals" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "populations" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "models" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "plots" = reactiveValues(
      file_path = NA,
      sheets = NA
    )
  )
}

dropdown_values <- function() {
  list(
    "scenarios" = reactiveValues(
      individual_id = c(),
      population_id = c(),
      outputpath_id = c(),
      steadystatetime_unit = ospsuite::ospUnits$Time |> sapply(function(x) x) |> unname()
    ),
    "individuals" = reactiveValues(
      species_options = ospsuite::Species |> sapply(function(x) x) |> unname(),
      specieshuman_options = ospsuite::HumanPopulation |> sapply(function(x) x) |> unname(),
      gender_options = ospsuite::Gender |> sapply(function(x) x) |> unname()
    ),
    "populations" = reactiveValues(
      weight_unit = ospsuite::ospUnits$Mass |> sapply(function(x) x) |> unname(),
      height_unit = ospsuite::ospUnits$Length |> sapply(function(x) x) |> unname(),
      bmi_unit = ospsuite::ospUnits$BMI |> sapply(function(x) x) |> unname()
    ),
    "plots" = reactiveValues(
      datatype_options = c("simulated", "observed"),
      scenario_options = c(),
      path_options = c(),
      datacombinedname_options = c(),
      plottype_options = c("individual",
                           "population",
                           "observedVsSimulated",
                           "residualVsSimulated",
                           "residualsVsTime"),
      axisscale_options = c("lin", "log"),
      aggregation_options = ospsuite::DataAggregationMethods |> sapply(function(x) x) |> unname()
    )
  )
}
