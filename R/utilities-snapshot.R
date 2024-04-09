#' Extract unique expression profiles for a PK-Sim snapshot.
#'
#' @param snapshot
#'
#' @return A named list with "uniqueExpressionProfiles" list of unique expression profiles and
#' "expressionProfileMapping" mapping of all expression profiles names to a respective
#' unique profile.
#' @export
#'
#' @examples
extractUniqueExpressionProfilesFromSnapshot <- function(snapshot) {
  snapshotExpressionProfiles <- snapshot$ExpressionProfiles

  # List of species for which expression profiles are defined in the project
  speciesList <- list()
  # Mapping of epxression profiles names to unique expression profiles
  epxProfilesMapping <- list()

  for (expProfile in snapshotExpressionProfiles) {
    expProfileName <- paste(expProfile$Molecule, expProfile$Species, expProfile$Category, sep = "|")

    species <- expProfile$Species
    proteinName <- expProfile$Molecule

    # If no protein for the respective species has been stored so far,
    # store this instance
    if (is.null(speciesList[[species]][[proteinName]])){
      speciesList[[species]][[proteinName]] <- list(expProfile)
      epxProfilesMapping[[expProfileName]] <- expProfileName
      next
    }

    # Compare the current expression profile with each expression profile stored
    # for this protein
    profileIsUnique <- TRUE
    for (expProfileReference in speciesList[[species]][[proteinName]]){
      expProfileReferenceName <- paste(expProfileReference$Molecule, expProfileReference$Species, expProfileReference$Category, sep = "|")
      # If there is at least one profile that is equal, stop comparison and continue
      if (.isExpProfilesEqual(expProfileReference, expProfile)){
        profileIsUnique <- FALSE
        epxProfilesMapping[[expProfileName]] <- expProfileReferenceName
        break
      }
    }

    if (profileIsUnique){
      speciesList[[species]][[proteinName]] <- c(speciesList[[species]][[proteinName]], list(expProfile))
      epxProfilesMapping[[expProfileName]] <- expProfileName
    }
  }

  return (list("uniqueExpressionProfiles" = speciesList,
          "expressionProfileMapping" = epxProfilesMapping))
}

removeIdenticalExpProfilesFromSnapshot <- function(snapshot){
  uniqueExpProfiles <- extractUniqueExpressionProfilesFromSnapshot(snapshot = pkSimSnapshot)

  # Replace the "ExpressionProfiles" section with the list of unique profiles
  # unlisting twice as the first level is "species" and second is "molecule name"
  snapshot$ExpressionProfiles <- unlist(
    unlist(uniqueExpProfiles$uniqueExpressionProfiles, recursive = FALSE,
                                        use.names = FALSE),
    recursive = FALSE,
    use.names = FALSE)

  # Replace the names of non-unique profiles in the individuals
  for (individualIdx in seq_along(snapshot$Individuals)){
    individual <- snapshot$Individuals[[individualIdx]]

    for (expProfileIdx in seq_along(individual$ExpressionProfiles)){
      snapshot$Individuals[[individualIdx]]$ExpressionProfiles[[expProfileIdx]] <- uniqueExpProfiles$expressionProfileMapping[[individual$ExpressionProfiles[[expProfileIdx]]]]
    }
  }

  return(snapshot)
}

#' Test two expression profiles for uniqueness
#'
#' @param profile1 First profile as extracted from a PK-Sim snapshot
#' @param profile2 Second profile as extracted from a PK-Sim snapshot
#' @param compareMolecule Should molecule name be compared? `TRUE` by default
#' @param compareCategory Should category (== "phenotype") be compared? `FALSE` by default.
#'
#'
#' @return `TRUE` if profiles are equal, `FALSE` otherwise.
.isExpProfilesEqual <- function(profile1, profile2,
                                compareMolecule = TRUE,
                                compareCategory = FALSE){
  # Different types are always non equal, as they have different structures
  if (profile1$Type != profile2$Type){
    return(FALSE)
  }
  if (compareMolecule && profile1$Molecule != profile2$Molecule){
    return(FALSE)
  }
  if (compareCategory && profile1$Category != profile2$Category){
    return(FALSE)
  }

  # Species equal?
  if (profile1$Species != profile2$Species){
    return(FALSE)
  }

  # Ontogeny equal?
  # Using identical to test for NULL (no ontogeny defined)
  if (!identical(profile1$Ontogeny, profile2$Ontogeny)){
    return(FALSE)
  }

  # Test expression values
  if (!identical(profile1$Parameters, profile2$Parameters)){
    return(FALSE)
  }

  # Type-specific comparisons
  switch(profile1$Type,
         "Transporter" = {
           # Transport type equal?
           if (profile1$TransportType != profile2$TransportType){
             return(FALSE)
           }
           # Expression fractions equal?
           if (!identical(profile1$Expression, profile2$Expression)){
             return(FALSE)
           }
         },
         "Enzyme" = {
           # Localization equal?
           if (profile1$Localization != profile2$Localization){
             return(FALSE)
           }
         },
         "OtherProtein" = {
           # Localization equal?
           if (profile1$Localization != profile2$Localization){
             return(FALSE)
           }
         }
  )
  return(TRUE)
}

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
