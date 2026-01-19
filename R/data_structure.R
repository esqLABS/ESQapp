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
    "applications" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "plots" = reactiveValues(
      file_path = NA,
      sheets = NA
    )
  )
}

DROPDOWN_COLUMN_TYPE_LIST <- list(
  "scenarios" = list(
    "Scenarios" = c("IndividualId", "PopulationId", "ApplicationProtocol", "SteadyStateTime")
  ),
  "individuals" = list(
    "IndividualBiometrics" = c("Species", "Population", "Gender")
  ),
  "populations" = list(
    "Demographics" = c("species", "population", "weightUnit", "heightMax", "BMIUnit")
  ),
  "plots" = list(
    "DataCombined" = c("dataType", "scenario", "path", "dataSet"),
    "plotConfiguration" = c("DataCombinedName", "plotType", "xAxisScale", "yAxisScale", "aggregation"),
    "exportConfiguration" = c("plotGridName")
  )
)

# Column types for numeric conversion during export
NUMERIC_COLUMN_TYPE_LIST <- list(
  "scenarios" = list(
    "Scenarios" = c("SteadyStateTime")
  ),
  "individuals" = list(
    "IndividualBiometrics" = c("Age [year(s)]", "Height [cm]", "Weight [kg]")
  ),
  "populations" = list(
    "Demographics" = c("numberOfIndividuals", "proportionOfFemales",
                       "ageMin", "ageMax", "weightMin", "weightMax",
                       "heightMin", "heightMax", "BMIMin", "BMIMax")
  ),
  "plots" = list(
    "DataCombined" = c("xOffsets", "yOffsets", "xScaleFactors", "yScaleFactors"),
    "plotConfiguration" = c("xValuesLimits", "yValuesLimits", "quantiles", "nsd", "foldDistance"),
    "exportConfiguration" = c("width")
  )
)

dropdown_values <- function() {
  list(
    "scenarios" = reactiveValues(
      individual_id = c(),
      population_id = c(),
      outputpath_id = c(),
      outputpath_id_alias = list(),
      model_parameters = c(),
      model_files = c(),
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
    "applications" = reactiveValues(
      application_protocols = c()
    ),
    "plots" = reactiveValues(
      datatype_options = c("simulated", "observed"),
      scenario_options = c(),
      path_options = c(),
      datacombinedname_options = c(),
      plottype_options = c(
        "individual",
        "population",
        "observedVsSimulated",
        "residualVsSimulated",
        "residualsVsTime"
      ),
      axisscale_options = c("lin", "log"),
      aggregation_options = ospsuite::DataAggregationMethods |> sapply(function(x) x) |> unname()
    )
  )
}

metadata_values <- function() {
  list(
    "plots" = reactiveValues(
      loaddata_metadata = list()
    )
  )
}


DataStructure <- R6::R6Class("DataStructure",
  public = list(
    scenarios = NULL,
    individuals = NULL,
    populations = NULL,
    models = NULL,
    applications = NULL,
    plots = NULL,
    initialize = function() {
      self$scenarios <- reactiveValues(file_path = NA, sheets = NA)
      self$individuals <- reactiveValues(file_path = NA, sheets = NA)
      self$populations <- reactiveValues(file_path = NA, sheets = NA)
      self$models <- reactiveValues(file_path = NA, sheets = NA)
      self$applications <- reactiveValues(file_path = NA, sheets = NA)
      self$plots <- reactiveValues(file_path = NA, sheets = NA)
    },
    get_config_files = function() {
      c("scenarios", "individuals", "populations", "models", "applications", "plots")
    },
    is_sheet_empty = function(file_path, sheet) {
      # Read the sheet without importing data to check dimensions
      sheet_data <-  suppressMessages(suppressWarnings(
                        readxl::read_excel(file_path, sheet = sheet, .name_repair = "minimal")
                     ))

      # Check if the sheet has data
      return(nrow(sheet_data) == 0 & ncol(sheet_data) == 0)
    },
    check_empty_column_names = function(file_path, sheet_name) {
      empty_columns <- c() # Vector to store empty column names

      # Read the entire sheet (to access column names)
      sheet_data <-  suppressMessages(suppressWarnings(
                        readxl::read_excel(file_path, sheet = sheet_name, .name_repair = "minimal")
                     ))
      # Check for empty or auto-assigned column names (e.g., ...1, ...2, etc.)
      for (col_name in names(sheet_data)) {
        # Check if the column name is NA, empty, or follows the auto-generated pattern (e.g., ...1, ...2)
        if (is.na(col_name) || col_name == "" || grepl("^\\.{3}[0-9]+$", col_name)) {
          empty_columns <- c(empty_columns, col_name) # Add empty or auto-assigned column name to the list
        }
      }

      # Return the empty or auto-assigned column names, or NULL if none are empty
      if (length(empty_columns) > 0) {
        return(empty_columns)
      } else {
        return(NULL)
      }
    },
    # Import sheets ============================================================
    add_sheet = function(config_file, sheet_name, warning_obj) {

      if (is.null(self[[config_file]][[sheet_name]])) {
        self[[config_file]][[sheet_name]] <- reactiveValues()
      }

      # Import the sheet using rio if not empty
      if (!self$is_sheet_empty(self[[config_file]]$file_path, sheet_name)) {
        # Check if any column names are empty
        empty_columns <- self$check_empty_column_names(self[[config_file]]$file_path, sheet_name)
        if (!is.null(empty_columns)) {
          warning_obj$add_warning(
            config_file,
            sheet_name,
            sprintf("Sheet contains empty column names: %s", paste(empty_columns, collapse = ", "))
          )
        }

        self[[config_file]][[sheet_name]]$original <- suppressMessages(suppressWarnings(
                                                        rio::import(
                                                          self[[config_file]]$file_path,
                                                          sheet = sheet_name,
                                                          col_types = "text"
                                                        )
                                                      ))
        self[[config_file]][[sheet_name]]$modified <- self[[config_file]][[sheet_name]]$original
      } else {
        warning_obj$add_warning(config_file, sheet_name, "Sheet is empty", warning_code = "empty_sheet")
        # Remove sheet from the list of sheets
        self[[config_file]][[sheet_name]] <- NULL
        self[[config_file]]$sheets <- setdiff(self[[config_file]]$sheets, sheet_name)
      }
    },
    # Manage sheets ============================================================
    remove_sheet = function(config_name, sheet_name) {
      if (!(sheet_name %in% self[[config_name]]$sheets)) {
        message("Sheet does not exist")
        return()
      } else {
        # Remove the sheet name from the list of sheets
        self[[config_name]]$sheets <- setdiff(self[[config_name]]$sheets, sheet_name)

        # Remove the corresponding reactive values
        self[[config_name]][[sheet_name]] <- NULL
      }
    },
    create_new_sheet = function(config_name, sheet_name) {
      if (sheet_name %in% self[[config_name]]$sheets) {
        message("Sheet already exists")
        return()
      } else {
        self[[config_name]]$sheets <- c(self[[config_name]]$sheets, sheet_name)

        self[[config_name]][[sheet_name]] <- reactiveValues()

        self[[config_name]][[sheet_name]]$modified <- data.frame(
          `Container Path` = NA_character_,
          `Parameter Name` = NA_character_,
          Value = NA_real_,
          Units = NA_character_,
          check.names = FALSE,
          row.names = NULL
        )

      }
    },
    rename_individual_sheet = function(config_name, old_sheet_name, new_sheet_name) {
      if (!(old_sheet_name %in% self[[config_name]]$sheets)) {
        message("Old sheet does not exist")
        return()
      }

      if (new_sheet_name %in% self[[config_name]]$sheets) {
        message("New sheet name already exists")
        return()
      }

      # Rename the sheet in the list of sheets
      self[[config_name]]$sheets <- gsub(old_sheet_name, new_sheet_name, self[[config_name]]$sheets)

      # Rename the reactive values
      self[[config_name]][[new_sheet_name]] <- self[[config_name]][[old_sheet_name]]
      self[[config_name]][[old_sheet_name]] <- NULL
    }
  )
)


WarningHandler <- R6::R6Class(
  "WarningHandler",
  public = list(

    # Store warning messages
    warning_messages = NULL,
    invalid_sheets_name = NULL,


    # Initialize
    initialize = function() {
      self$warning_messages <- reactiveValues()
    },

    # Method to add a warning
    add_warning = function(config_file, sheet_name, message, warning_code = NULL) {
      self$warning_messages$config_files <- c(self$warning_messages$config_files, config_file)
      warning_msg <- sprintf("Warning for sheet <b>'%s'</b>: %s", sheet_name, message)
      self$warning_messages[[config_file]] <- c(self$warning_messages[[config_file]], warning_msg)

      if (!is.null(warning_code)) {
        self$invalid_sheets_name[[config_file]] <- c(self$invalid_sheets_name[[config_file]], sheet_name)
      }

    }
  )
)
