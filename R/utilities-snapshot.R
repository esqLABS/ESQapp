#' Create a "Scenarios" file from a given snapshot
#'
#' @param snapshot PK-Sim snapshot
#' @param outputPath Path to the excel file where to write the outputs
#'
#' @return
#' @export
#'
#' @examples
createScenariosFromSnapshots <- function(snapshot, outputPath){
  snapshotSimulations <- snapshot$Simulations
  scenariosDf <- data.frame(list(
    "Scenario_name" = character(),
    "IndividualId" = character(),
    "PopulationId" = character(),
    "ReadPopulationFromCSV" = logical(),
    "ModelParameterSheets" = character(),
    "ApplicationProtocol" = character(),
    "SimulationTime" = character(),
    "SimulationTimeUnit" = numeric(),
    "SteadyState" = logical(),
    "SteadyStateTime" = numeric(),
    "SteadyStateTimeUnit" = character(),
    "ModelFile" = character(),
    "OutputPathsIds" = character()
  ))
  outputPathsDf <- data.frame(list(
    "OutputPathId" = character(),
    "OutputPath" = character()
  ))

  # Named list of output selections,
  # where names are the output paths, and the values are the aliases
  outputPathsAliases <- list()

  for (simulation in snapshotSimulations) {
    # For each simulation, create a scenario
    simulationName <- simulation$Name
    outputSchema <- .createOutputSchemaStringFromJson(simulation$OutputSchema)

    # Multiple output paths can be defined for each simulation.
    # In the "Scenarios" sheet, output aliases are defined, that are mapped to
    # output paths in the sheet "OutputPaths".
    # The following loop iterates through all output paths of the simulation and
    # constructs a list of output aliases.
    outputPaths <- simulation$OutputSelections
    outputAliases <- lapply(outputPaths, function(x){
      # Check if this path has already been added to the "OutputPaths"
      alias <- outputPathsAliases[[x]]
      if (is.null(alias)){
        alias <- paste0("Output_", length(outputPathsAliases) + 1)
        outputPathsAliases[[x]] <<- alias
      }
      return(alias)
    })

    # Create a scenario row for this simulation
    scenarioRow <- data.frame(list(
      "Scenario_name" = simulationName,
      "IndividualId" = NA,
      "PopulationId" = NA,
      "ReadPopulationFromCSV" = NA,
      "ModelParameterSheets" = NA,
      "ApplicationProtocol" = NA,
      "SimulationTime" = outputSchema$Intervals,
      "SimulationTimeUnit" = outputSchema$Unit,
      "SteadyState" = FALSE,
      "SteadyStateTime" = NA,
      "SteadyStateTimeUnit" = NA,
      "ModelFile" = paste0(simulationName, ".pkml"),
      "OutputPathsIds" = paste(outputAliases, collapse = ", ")
    ))
    scenariosDf <- rbind(scenariosDf, scenarioRow)
  }
  outputPathsDf <- rbind(outputPathsDf,
                         data.frame(list(
    "OutputPathId" = unlist(outputPathsAliases, use.names = FALSE),
    "OutputPath" = names(outputPathsAliases)
  )))

  esqlabsR::writeExcel(data = list("Scenarios" = scenariosDf,
                                   "OutputPaths" = outputPathsDf),
                       path = outputPath)

}

#' Create output simulation time string form output schema in json format
#'
#' @param outputSchemaJson The 'OutputSchema' section from a Simulation of a json
#' PK-Sim snapshot
#'
#' @return
#' A named list, with 'Intervals' a string where each output interval is defined as
#' <start, end, resolution>, and intervals are separated by a ';',
#' and 'Unit' the unit of the start time of the first interval.
#' All values are transformed to 'Unit'.
.createOutputSchemaStringFromJson <- function(outputSchemaJson){
  outputIntervals <- list()
  # All values will have the unit of the very first "Start time" parameter
  schemaUnit <- NULL
  # Iterate through all output intervals defined
  for (outputInterval in outputSchemaJson){
    # Each output interval is defined by the parameters "Start time", "End time",
    # and "Resolution". Store the values and the units of the parameters separately.
    paramValues <- list()
    paramUnits <- list()

    for (param in outputInterval$Parameters){
      # The unit of the very first parameter "Start time" will be the unit of
      # all values
      if (param$Name == "Start time"){
        schemaUnit <- schemaUnit %||% param$Unit
      }
      paramValues[[param$Name]] <- param$Value
      paramUnits[[param$Name]] <- param$Unit
    }
    # Combine parameter values to a string. All values are converted to the
    # unit of the very first parameter "Start time".
    intervalString <- paste(ospsuite::toUnit(ospsuite::ospDimensions$Time,
                                             paramValues[["Start time"]],
                                             targetUnit = schemaUnit,
                                             sourceUnit = paramUnits[["Start time"]]),
                            ospsuite::toUnit(ospsuite::ospDimensions$Time,
                                             paramValues[["End time"]],
                                             targetUnit = schemaUnit,
                                             sourceUnit = paramUnits[["End time"]]),
                            ospsuite::toUnit(ospsuite::ospDimensions$Resolution,
                                             paramValues[["Resolution"]],
                                             targetUnit = paste0("pts/", schemaUnit),
                                             sourceUnit = paramUnits[["Resolution"]]),
                            sep = ", ")
    outputIntervals <- c(outputIntervals, intervalString)
  }
  return(list("Intervals" = paste(outputIntervals, collapse = "; "),
         "Unit" = schemaUnit))
}
