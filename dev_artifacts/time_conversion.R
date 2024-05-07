.createOutputSchemaStringFromJson <- function(outputSchemaJson, schemaUnit = NULL){
  outputIntervals <- list()
  # All values will have the unit of the very first "Start time" parameter
  schemaUnit <- schemaUnit
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
                                             sourceUnit = paste0("pts/", paramUnits[["Resolution"]])),
                            sep = ", ")
    outputIntervals <- c(outputIntervals, intervalString)
  }
  return(list("Intervals" = paste(outputIntervals, collapse = "; "),
              "Unit" = schemaUnit))
}

# JSON schema
json_example <- jsonlite::fromJSON('dev_artifacts/project-test.json', simplifyVector = FALSE)

# Run the function
.createOutputSchemaStringFromJson(json_example, schemaUnit = 'h')


