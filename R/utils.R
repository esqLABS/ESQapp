#' Convert points from a specified unit to a target unit using pts/day as base.
#'
#' This function converts a given value in points from one of the allowed current units
#' ("pts/s", "pts/min", "pts/h", "pts/day") to a target unit. The conversion is done
#' via an intermediate conversion to pts/day. If the target unit is:
#' - "pts/day(s)": the pts/day value is returned.
#' - "pts/week(s)": the pts/day value is divided by 7 (i.e., average pts/day for a week).
#' - "pts/month(s)": the pts/day value is divided by 30 (i.e., average pts/day for a month).
#' - "pts/year(s)": the pts/day value is divided by 365 (i.e., average pts/day for a year).
#' - "pts/ks": the pts/day value is converted to pts/ks using the factor 1000/86400.
#'
#' @param value Numeric value representing the number of points in the current unit.
#' @param current_unit A string specifying the current unit.
#'                     Allowed values: "pts/s", "pts/min", "pts/h", "pts/day".
#' @param target_unit A string specifying the target unit.
#'                    Allowed values: "pts/day(s)", "pts/week(s)", "pts/month(s)", "pts/year(s)", "pts/ks".
#'
#' @return A numeric value representing the points converted to the target unit using the pts/day logic.
#'
.convertPoints <- function(value, current_unit, target_unit) {
  # Validate allowed current units
  allowed_current_units <- c("pts/s", "pts/min", "pts/h", "pts/day")
  if (!current_unit %in% allowed_current_units) {
    stop("Unsupported current unit: ", current_unit)
  }

  # Validate allowed target units
  allowed_target_units <- c("pts/day(s)", "pts/week(s)", "pts/month(s)", "pts/year(s)", "pts/ks")
  if (!target_unit %in% allowed_target_units) {
    stop("Unsupported target unit: ", target_unit)
  }

  # Convert input value to points per day (pts/day)
  pts_day <- switch(current_unit,
                    "pts/s"   = value * 86400,   # 1 day = 86400 seconds
                    "pts/min" = value * 1440,    # 1 day = 1440 minutes
                    "pts/h"   = value * 24,      # 1 day = 24 hours
                    "pts/day" = value
  )

  # Apply specific logic based on target unit:
  converted_value <- switch(target_unit,
                            "pts/day(s)"  = pts_day,
                            "pts/week(s)" = pts_day * (1/7),    # Average pts/day from a weekly rate
                            "pts/month(s)"= pts_day * (1/30),   # Average pts/day from a monthly rate
                            "pts/year(s)" = pts_day * (1/365),   # Average pts/day from a yearly rate
                            "pts/ks"      = pts_day * (1000/86400) # Convert pts/day to pts/ks (1 ks = 1000 sec)
  )

  return(converted_value)
}



#' Create output simulation time string form output schema in json format
#'
#' @param outputSchemaJson The 'OutputSchema' section from a Simulation of a json
#' @param schemaUnit The unit of the start time of the first interval
#' PK-Sim snapshot
#'
#' @return
#' A named list, with 'Intervals' a string where each output interval is defined as
#' <start, end, resolution>, and intervals are separated by a ';',
#' and 'Unit' the unit of the start time of the first interval.
#' All values are transformed to 'Unit'.
.createOutputSchemaStringFromJson <- function(outputSchemaJson, schemaUnit = NULL) {
  outputIntervals <- list()
  # All values will have the unit of the very first "Start time" parameter
  schemaUnit <- schemaUnit
  # Iterate through all output intervals defined
  for (outputInterval in outputSchemaJson) {
    # Each output interval is defined by the parameters "Start time", "End time",
    # and "Resolution". Store the values and the units of the parameters separately.
    paramValues <- list()
    paramUnits <- list()

    for (param in outputInterval$Parameters) {
      # The unit of the very first parameter "Start time" will be the unit of
      # all values


      if (param$Name == "Start time") {
        schemaUnit <- schemaUnit %||% param$Unit
      }
      paramValues[[param$Name]] <- param$Value
      paramUnits[[param$Name]] <- param$Unit
    }
    # Combine parameter values to a string. All values are converted to the
    # unit of the very first parameter "Start time".
    intervalString <- paste(
      ospsuite::toUnit(ospsuite::ospDimensions$Time,
        paramValues[["Start time"]],
        targetUnit = schemaUnit,
        sourceUnit = paramUnits[["Start time"]]
      ),
      ospsuite::toUnit(ospsuite::ospDimensions$Time,
        paramValues[["End time"]],
        targetUnit = schemaUnit,
        sourceUnit = paramUnits[["End time"]]
      ),
      {
        if(!(schemaUnit %in% c("s", "min", "h"))) {
          .convertPoints(
            value        = paramValues[["Resolution"]],
            current_unit = paramUnits[["Resolution"]],
            target_unit  = paste0("pts/", schemaUnit)
          )
        } else {
          ospsuite::toUnit(ospsuite::ospDimensions$Resolution,
                           paramValues[["Resolution"]],
                           targetUnit = paste0("pts/", schemaUnit),
                           sourceUnit = paste0(paramUnits[["Resolution"]])
          )
        }
      },
      sep = ", "
    )
    outputIntervals <- c(outputIntervals, intervalString)
  }
  return(list(
    "Intervals" = paste(outputIntervals, collapse = "; "),
    "Unit" = schemaUnit
  ))
}


#' Get current package version
#' @export
app_version <- function() {
  utils::packageDescription('ESQapp')$Version
}
