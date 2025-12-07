#' @title ProjectConfigurationJSON
#' @description R6 class for importing and validating JSON-based project configurations.
#' Replaces Excel-based configuration with JSON as the primary data source.
#'
#' @importFrom R6 R6Class
#' @importFrom jsonlite fromJSON toJSON
#' @export
ProjectConfigurationJSON <- R6::R6Class(

  "ProjectConfigurationJSON",
  public = list(
    #' @field file_path Path to the JSON configuration file
    file_path = NULL,

    #' @field base_path Base directory path (directory containing the JSON file)
    base_path = NULL,

    #' @field raw_data Raw parsed JSON data
    raw_data = NULL,

    #' @field project_settings Project configuration settings (paths, files)
    project_settings = NULL,

    #' @field scenarios Scenarios configuration
    scenarios = NULL,

    #' @field individuals Individuals configuration
    individuals = NULL,

    #' @field populations Populations configuration
    populations = NULL,

    #' @field model_parameters Model parameter sets configuration
    model_parameters = NULL,

    #' @field applications Applications configuration
    applications = NULL,

    #' @field plots Plots configuration
    plots = NULL,

    #' @field populations_csv Population CSV data
    populations_csv = NULL,

    #' @field errors List of validation errors
    errors = NULL,

    #' @field warnings List of validation warnings
    warnings = NULL,

    #' @description Initialize ProjectConfigurationJSON object
    #' @param file_path Path to the JSON configuration file
    #' @return A new ProjectConfigurationJSON object
    initialize = function(file_path = NULL) {
      self$errors <- ValidationErrorCollection$new()
      self$warnings <- ValidationWarningCollection$new()

      if (!is.null(file_path)) {
        self$load(file_path)
      }
    },

    #' @description Load and parse JSON configuration file
    #' @param file_path Path to the JSON configuration file
    #' @return Self (invisibly)
    load = function(file_path) {
      # Validate file exists
      if (!file.exists(file_path)) {
        self$errors$add(
          code = "E001",
          section = "file",
          message = sprintf("Configuration file not found: %s", file_path)
        )
        return(invisible(self))
      }

      # Validate file extension
      if (!grepl("\\.json$", file_path, ignore.case = TRUE)) {
        self$errors$add(
          code = "E002",
          section = "file",
          message = "Configuration file must be a JSON file (.json extension)"
        )
        return(invisible(self))
      }

      self$file_path <- normalizePath(file_path, winslash = "/")
      self$base_path <- dirname(self$file_path)

      # Parse JSON
      tryCatch({
        self$raw_data <- jsonlite::fromJSON(
          self$file_path,
          simplifyVector = FALSE,
          simplifyDataFrame = FALSE
        )
      }, error = function(e) {
        self$errors$add(
          code = "E003",
          section = "file",
          message = sprintf("Failed to parse JSON: %s", conditionMessage(e))
        )
      })

      if (self$errors$has_errors()) {
        return(invisible(self))
      }

      # Parse each section
      private$parse_project_configuration()
      private$parse_scenarios()
      private$parse_individuals()
      private$parse_populations()
      private$parse_model_parameters()
      private$parse_applications()
      private$parse_plots()
      private$parse_populations_csv()

      # Run cross-validation
      private$validate_cross_references()

      invisible(self)
    },

    #' @description Check if configuration has any errors
    #' @return Logical indicating if there are errors
    has_errors = function() {
      self$errors$has_errors()
    },

    #' @description Check if configuration has any warnings
    #' @return Logical indicating if there are warnings
    has_warnings = function() {
      self$warnings$has_warnings()
    },

    #' @description Get all sheet names for a configuration section

#' @param section Section name ("scenarios", "individuals", "populations",
#'   "model_parameters", "applications", "plots")
    #' @return Character vector of sheet names
    get_sheet_names = function(section) {
      data <- switch(section,
        "scenarios" = self$scenarios,
        "individuals" = self$individuals,
        "populations" = self$populations,
        "model_parameters" = self$model_parameters,
        "models" = self$model_parameters,
        "applications" = self$applications,
        "plots" = self$plots,
        NULL
      )

      if (is.null(data)) {
        return(character(0))
      }

      names(data)
    },

    #' @description Get data frame for a specific sheet
    #' @param section Section name
    #' @param sheet Sheet name
    #' @return Data frame or NULL if not found
    get_sheet_data = function(section, sheet) {
      data <- switch(section,
        "scenarios" = self$scenarios,
        "individuals" = self$individuals,
        "populations" = self$populations,
        "model_parameters" = self$model_parameters,
        "models" = self$model_parameters,
        "applications" = self$applications,
        "plots" = self$plots,
        NULL
      )

      if (is.null(data) || !sheet %in% names(data)) {
        return(NULL)
      }

      data[[sheet]]
    },

    #' @description Get resolved file path for a configuration property
    #' @param property Property name (e.g., "modelFolder", "dataFile")
    #' @return Resolved absolute path or NULL
    get_path = function(property) {
      if (is.null(self$project_settings)) {
        return(NULL)
      }

      value <- self$project_settings[[property]]
      if (is.null(value) || value == "") {
        return(NULL)
      }

      # Resolve relative path
      file.path(self$base_path, value)
    },

    #' @description Export configuration to JSON file
    #' @param output_path Path for output JSON file
    #' @return Logical indicating success
    export = function(output_path) {
      tryCatch({
        json_data <- private$build_json_structure()
        json_string <- jsonlite::toJSON(json_data, pretty = TRUE, auto_unbox = TRUE, null = "null")
        writeLines(json_string, output_path)
        TRUE
      }, error = function(e) {
        self$errors$add(
          code = "E100",
          section = "export",
          message = sprintf("Failed to export JSON: %s", conditionMessage(e))
        )
        FALSE
      })
    },

    #' @description Print summary of the configuration
    print = function() {
      cat("ProjectConfigurationJSON\n")
      cat("========================\n")
      cat(sprintf("File: %s\n", self$file_path %||% "(not loaded)"))
      cat(sprintf("Errors: %d\n", self$errors$count()))
      cat(sprintf("Warnings: %d\n", self$warnings$count()))

      if (!is.null(self$scenarios)) {
        cat(sprintf("\nScenarios: %d sheets\n", length(self$scenarios)))
        for (name in names(self$scenarios)) {
          cat(sprintf("  - %s: %d rows\n", name, nrow(self$scenarios[[name]])))
        }
      }

      if (!is.null(self$individuals)) {
        cat(sprintf("\nIndividuals: %d sheets\n", length(self$individuals)))
        for (name in names(self$individuals)) {
          cat(sprintf("  - %s: %d rows\n", name, nrow(self$individuals[[name]])))
        }
      }

      if (!is.null(self$populations)) {
        cat(sprintf("\nPopulations: %d sheets\n", length(self$populations)))
        for (name in names(self$populations)) {
          cat(sprintf("  - %s: %d rows\n", name, nrow(self$populations[[name]])))
        }
      }

      if (!is.null(self$model_parameters)) {
        cat(sprintf("\nModel Parameters: %d sheets\n", length(self$model_parameters)))
        for (name in names(self$model_parameters)) {
          cat(sprintf("  - %s: %d rows\n", name, nrow(self$model_parameters[[name]])))
        }
      }

      if (!is.null(self$applications)) {
        cat(sprintf("\nApplications: %d sheets\n", length(self$applications)))
        for (name in names(self$applications)) {
          cat(sprintf("  - %s: %d rows\n", name, nrow(self$applications[[name]])))
        }
      }

      if (!is.null(self$plots)) {
        cat(sprintf("\nPlots: %d sheets\n", length(self$plots)))
        for (name in names(self$plots)) {
          cat(sprintf("  - %s: %d rows\n", name, nrow(self$plots[[name]])))
        }
      }

      invisible(self)
    }
  ),

  private = list(
    #' Parse projectConfiguration section
    parse_project_configuration = function() {
      section <- self$raw_data$projectConfiguration

      if (is.null(section)) {
        self$errors$add(
          code = "E010",
          section = "projectConfiguration",
          message = "Missing 'projectConfiguration' section in JSON"
        )
        return()
      }

      # Convert rows to named list
      self$project_settings <- list()

      rows <- section$rows
      if (is.null(rows) || length(rows) == 0) {
        self$warnings$add(
          code = "W010",
          section = "projectConfiguration",
          message = "Empty 'projectConfiguration' section"
        )
        return()
      }

      for (row in rows) {
        property <- row$Property
        value <- row$Value
        if (!is.null(property)) {
          self$project_settings[[property]] <- value
        }
      }

      # Validate required properties
      required_props <- c("modelFolder", "configurationsFolder", "scenariosFile")
      for (prop in required_props) {
        if (is.null(self$project_settings[[prop]]) || self$project_settings[[prop]] == "") {
          self$warnings$add(
            code = "W011",
            section = "projectConfiguration",
            message = sprintf("Missing recommended property: %s", prop)
          )
        }
      }
    },

    #' Parse Scenarios section
    parse_scenarios = function() {
      section <- self$raw_data$Scenarios

      if (is.null(section)) {
        self$warnings$add(
          code = "W020",
          section = "Scenarios",
          message = "Missing 'Scenarios' section in JSON"
        )
        return()
      }

      self$scenarios <- private$parse_section_sheets(section, "Scenarios")

      # Validate Scenarios sheet
      if ("Scenarios" %in% names(self$scenarios)) {
        df <- self$scenarios$Scenarios
        required_cols <- c("Scenario_name", "ModelFile")

        for (col in required_cols) {
          if (!col %in% names(df)) {
            self$errors$add(
              code = "E021",
              section = "Scenarios",
              sheet = "Scenarios",
              message = sprintf("Missing required column: %s", col)
            )
          }
        }

        # Check for duplicate scenario names
        if ("Scenario_name" %in% names(df)) {
          dupes <- df$Scenario_name[duplicated(df$Scenario_name)]
          if (length(dupes) > 0) {
            self$errors$add(
              code = "E022",
              section = "Scenarios",
              sheet = "Scenarios",
              message = sprintf("Duplicate scenario names: %s", paste(unique(dupes), collapse = ", "))
            )
          }
        }
      }
    },

    #' Parse Individuals section
    parse_individuals = function() {
      section <- self$raw_data$Individuals

      if (is.null(section)) {
        self$warnings$add(
          code = "W030",
          section = "Individuals",
          message = "Missing 'Individuals' section in JSON"
        )
        return()
      }

      self$individuals <- private$parse_section_sheets(section, "Individuals")

      # Validate IndividualBiometrics sheet
      if ("IndividualBiometrics" %in% names(self$individuals)) {
        df <- self$individuals$IndividualBiometrics
        required_cols <- c("IndividualId", "Species")

        for (col in required_cols) {
          if (!col %in% names(df)) {
            self$errors$add(
              code = "E031",
              section = "Individuals",
              sheet = "IndividualBiometrics",
              message = sprintf("Missing required column: %s", col)
            )
          }
        }

        # Check for duplicate IndividualId
        if ("IndividualId" %in% names(df)) {
          dupes <- df$IndividualId[duplicated(df$IndividualId)]
          if (length(dupes) > 0) {
            self$errors$add(
              code = "E032",
              section = "Individuals",
              sheet = "IndividualBiometrics",
              message = sprintf("Duplicate IndividualId values: %s", paste(unique(dupes), collapse = ", "))
            )
          }
        }

        # Validate Species values
        valid_species <- c("Human", "Rat", "Mouse", "Rabbit", "Dog", "Minipig", "Monkey", "Beagle", "Cat")
        if ("Species" %in% names(df)) {
          invalid_species <- setdiff(unique(df$Species[!is.na(df$Species)]), valid_species)
          if (length(invalid_species) > 0) {
            self$warnings$add(
              code = "W033",
              section = "Individuals",
              sheet = "IndividualBiometrics",
              message = sprintf("Unknown Species values: %s", paste(invalid_species, collapse = ", "))
            )
          }
        }
      }
    },

    #' Parse Populations section
    parse_populations = function() {
      section <- self$raw_data$Populations

      if (is.null(section)) {
        self$warnings$add(
          code = "W040",
          section = "Populations",
          message = "Missing 'Populations' section in JSON"
        )
        return()
      }

      self$populations <- private$parse_section_sheets(section, "Populations")

      # Validate Demographics sheet
      if ("Demographics" %in% names(self$populations)) {
        df <- self$populations$Demographics
        required_cols <- c("PopulationName", "species", "numberOfIndividuals")

        for (col in required_cols) {
          if (!col %in% names(df)) {
            self$errors$add(
              code = "E041",
              section = "Populations",
              sheet = "Demographics",
              message = sprintf("Missing required column: %s", col)
            )
          }
        }

        # Validate numeric columns
        numeric_cols <- c("numberOfIndividuals", "proportionOfFemales", "ageMin", "ageMax",
                          "weightMin", "weightMax", "heightMin", "heightMax", "BMIMin", "BMIMax")

        for (col in numeric_cols) {
          if (col %in% names(df)) {
            values <- df[[col]]
            values <- values[!is.na(values) & values != ""]
            non_numeric <- values[!grepl("^-?[0-9]*\\.?[0-9]+$", values)]
            if (length(non_numeric) > 0) {
              self$warnings$add(
                code = "W042",
                section = "Populations",
                sheet = "Demographics",
                message = sprintf("Non-numeric values in column '%s': %s",
                                  col, paste(head(non_numeric, 3), collapse = ", "))
              )
            }
          }
        }
      }
    },

    #' Parse modelParameterSets section
    parse_model_parameters = function() {
      section <- self$raw_data$modelParameterSets

      if (is.null(section)) {
        self$warnings$add(
          code = "W050",
          section = "modelParameterSets",
          message = "Missing 'modelParameterSets' section in JSON"
        )
        return()
      }

      self$model_parameters <- private$parse_section_sheets(section, "modelParameterSets")

      # Validate each parameter sheet
      required_cols <- c("Container Path", "Parameter Name", "Value")

      for (sheet_name in names(self$model_parameters)) {
        df <- self$model_parameters[[sheet_name]]

        for (col in required_cols) {
          if (!col %in% names(df)) {
            self$errors$add(
              code = "E051",
              section = "modelParameterSets",
              sheet = sheet_name,
              message = sprintf("Missing required column: %s", col)
            )
          }
        }
      }
    },

    #' Parse Applications section
    parse_applications = function() {
      section <- self$raw_data$Applications

      if (is.null(section)) {
        self$warnings$add(
          code = "W060",
          section = "Applications",
          message = "Missing 'Applications' section in JSON"
        )
        return()
      }

      self$applications <- private$parse_section_sheets(section, "Applications")

      # Validate each application sheet
      required_cols <- c("Container Path", "Parameter Name", "Value")

      for (sheet_name in names(self$applications)) {
        df <- self$applications[[sheet_name]]

        for (col in required_cols) {
          if (!col %in% names(df)) {
            self$errors$add(
              code = "E061",
              section = "Applications",
              sheet = sheet_name,
              message = sprintf("Missing required column: %s", col)
            )
          }
        }
      }
    },

    #' Parse Plots section
    parse_plots = function() {
      section <- self$raw_data$Plots

      if (is.null(section)) {
        self$warnings$add(
          code = "W070",
          section = "Plots",
          message = "Missing 'Plots' section in JSON"
        )
        return()
      }

      self$plots <- private$parse_section_sheets(section, "Plots")

      # Validate DataCombined sheet
      if ("DataCombined" %in% names(self$plots)) {
        df <- self$plots$DataCombined
        required_cols <- c("DataCombinedName", "dataType")

        for (col in required_cols) {
          if (!col %in% names(df)) {
            self$errors$add(
              code = "E071",
              section = "Plots",
              sheet = "DataCombined",
              message = sprintf("Missing required column: %s", col)
            )
          }
        }

        # Validate dataType values
        valid_types <- c("simulated", "observed")
        if ("dataType" %in% names(df)) {
          invalid_types <- setdiff(unique(df$dataType[!is.na(df$dataType)]), valid_types)
          if (length(invalid_types) > 0) {
            self$errors$add(
              code = "E072",
              section = "Plots",
              sheet = "DataCombined",
              message = sprintf("Invalid dataType values: %s. Must be 'simulated' or 'observed'",
                                paste(invalid_types, collapse = ", "))
            )
          }
        }
      }

      # Validate plotConfiguration sheet
      if ("plotConfiguration" %in% names(self$plots)) {
        df <- self$plots$plotConfiguration
        required_cols <- c("plotID", "DataCombinedName", "plotType")

        for (col in required_cols) {
          if (!col %in% names(df)) {
            self$errors$add(
              code = "E073",
              section = "Plots",
              sheet = "plotConfiguration",
              message = sprintf("Missing required column: %s", col)
            )
          }
        }

        # Validate plotType values
        valid_plot_types <- c("individual", "population", "observedVsSimulated",
                              "residualsVsSimulated", "residualsVsTime", "residualVsSimulated")
        if ("plotType" %in% names(df)) {
          invalid_types <- setdiff(unique(df$plotType[!is.na(df$plotType)]), valid_plot_types)
          if (length(invalid_types) > 0) {
            self$warnings$add(
              code = "W074",
              section = "Plots",
              sheet = "plotConfiguration",
              message = sprintf("Unknown plotType values: %s", paste(invalid_types, collapse = ", "))
            )
          }
        }
      }
    },

    #' Parse populationsCSV section
    parse_populations_csv = function() {
      section <- self$raw_data$populationsCSV

      if (is.null(section)) {
        # Not an error - optional section
        return()
      }

      self$populations_csv <- private$parse_section_sheets(section, "populationsCSV")
    },

    #' Parse a section with multiple sheets into a named list of data frames
    parse_section_sheets = function(section, section_name) {
      result <- list()

      for (sheet_name in names(section)) {
        sheet_data <- section[[sheet_name]]

        tryCatch({
          df <- private$sheet_to_dataframe(sheet_data, section_name, sheet_name)
          if (!is.null(df)) {
            result[[sheet_name]] <- df
          }
        }, error = function(e) {
          self$errors$add(
            code = "E004",
            section = section_name,
            sheet = sheet_name,
            message = sprintf("Failed to parse sheet: %s", conditionMessage(e))
          )
        })
      }

      result
    },

    #' Convert sheet JSON structure to data frame
    sheet_to_dataframe = function(sheet_data, section_name, sheet_name) {
      column_names <- sheet_data$column_names
      rows <- sheet_data$rows

      # Handle column_names that might be a single string instead of array
      if (is.character(column_names) && length(column_names) == 1 && !is.null(names(column_names))) {
        # It's a named vector, convert to unnamed
        column_names <- unname(column_names)
      } else if (is.character(column_names) && length(column_names) == 1) {
        # Single column name as string - keep as is (will be length 1 vector)
        column_names <- column_names
      } else if (is.list(column_names)) {
        # Convert list to character vector
        column_names <- unlist(column_names)
      }

      # Handle empty sheets
      if (is.null(rows) || length(rows) == 0) {
        if (is.null(column_names) || length(column_names) == 0) {
          # Empty sheet with no columns - still create empty df
          # This is valid for sheets like ObservedDataNames
          return(data.frame(stringsAsFactors = FALSE, check.names = FALSE))
        }

        # Create empty data frame with column names
        df <- as.data.frame(
          matrix(ncol = length(column_names), nrow = 0),
          stringsAsFactors = FALSE
        )
        names(df) <- column_names
        return(df)
      }

      # Convert rows to data frame
      # Each row is a named list
      df <- do.call(rbind, lapply(rows, function(row) {
        # Convert NULL values to NA
        row <- lapply(row, function(x) if (is.null(x)) NA_character_ else as.character(x))
        as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
      }))

      # Ensure column order matches column_names if provided
      if (!is.null(column_names) && length(column_names) > 0) {
        # Add missing columns
        missing_cols <- setdiff(column_names, names(df))
        for (col in missing_cols) {
          df[[col]] <- NA_character_
        }

        # Reorder and select only defined columns
        df <- df[, column_names, drop = FALSE]
      }

      df
    },

    #' Validate cross-references between sections
    validate_cross_references = function() {
      # Validate IndividualId references in Scenarios
      if (!is.null(self$scenarios$Scenarios) && !is.null(self$individuals$IndividualBiometrics)) {
        scenario_individuals <- unique(self$scenarios$Scenarios$IndividualId)
        scenario_individuals <- scenario_individuals[!is.na(scenario_individuals)]

        defined_individuals <- self$individuals$IndividualBiometrics$IndividualId

        undefined_refs <- setdiff(scenario_individuals, defined_individuals)
        if (length(undefined_refs) > 0) {
          self$errors$add(
            code = "E080",
            section = "Scenarios",
            message = sprintf("Undefined IndividualId references: %s", paste(undefined_refs, collapse = ", "))
          )
        }

        # Check that individual sheets exist
        for (ind_id in defined_individuals) {
          if (!is.na(ind_id) && !ind_id %in% names(self$individuals)) {
            self$warnings$add(
              code = "W081",
              section = "Individuals",
              message = sprintf("No parameter sheet found for IndividualId: %s", ind_id)
            )
          }
        }
      }

      # Validate PopulationId references in Scenarios
      if (!is.null(self$scenarios$Scenarios) && !is.null(self$populations$Demographics)) {
        scenario_populations <- unique(self$scenarios$Scenarios$PopulationId)
        scenario_populations <- scenario_populations[!is.na(scenario_populations)]

        defined_populations <- self$populations$Demographics$PopulationName

        undefined_refs <- setdiff(scenario_populations, defined_populations)
        if (length(undefined_refs) > 0) {
          self$errors$add(
            code = "E082",
            section = "Scenarios",
            message = sprintf("Undefined PopulationId references: %s", paste(undefined_refs, collapse = ", "))
          )
        }
      }

      # Validate ApplicationProtocol references in Scenarios
      if (!is.null(self$scenarios$Scenarios) && !is.null(self$applications)) {
        scenario_apps <- unique(self$scenarios$Scenarios$ApplicationProtocol)
        scenario_apps <- scenario_apps[!is.na(scenario_apps)]

        defined_apps <- names(self$applications)

        undefined_refs <- setdiff(scenario_apps, defined_apps)
        if (length(undefined_refs) > 0) {
          self$errors$add(
            code = "E083",
            section = "Scenarios",
            message = sprintf("Undefined ApplicationProtocol references: %s", paste(undefined_refs, collapse = ", "))
          )
        }
      }

      # Validate ModelParameterSheets references in Scenarios
      if (!is.null(self$scenarios$Scenarios) && !is.null(self$model_parameters)) {
        all_param_refs <- c()
        for (ref in self$scenarios$Scenarios$ModelParameterSheets) {
          if (!is.na(ref)) {
            # Split comma-separated values
            refs <- trimws(strsplit(ref, ",")[[1]])
            all_param_refs <- c(all_param_refs, refs)
          }
        }
        all_param_refs <- unique(all_param_refs)

        defined_params <- names(self$model_parameters)

        undefined_refs <- setdiff(all_param_refs, defined_params)
        if (length(undefined_refs) > 0) {
          self$errors$add(
            code = "E084",
            section = "Scenarios",
            message = sprintf("Undefined ModelParameterSheets references: %s", paste(undefined_refs, collapse = ", "))
          )
        }
      }

      # Validate DataCombinedName references in plotConfiguration
      if (!is.null(self$plots$plotConfiguration) && !is.null(self$plots$DataCombined)) {
        plot_dc_refs <- unique(self$plots$plotConfiguration$DataCombinedName)
        plot_dc_refs <- plot_dc_refs[!is.na(plot_dc_refs)]

        defined_dc <- unique(self$plots$DataCombined$DataCombinedName)

        undefined_refs <- setdiff(plot_dc_refs, defined_dc)
        if (length(undefined_refs) > 0) {
          self$errors$add(
            code = "E085",
            section = "Plots",
            sheet = "plotConfiguration",
            message = sprintf("Undefined DataCombinedName references: %s", paste(undefined_refs, collapse = ", "))
          )
        }
      }

      # Validate scenario references in DataCombined
      if (!is.null(self$plots$DataCombined) && !is.null(self$scenarios$Scenarios)) {
        dc_scenarios <- unique(self$plots$DataCombined$scenario)
        dc_scenarios <- dc_scenarios[!is.na(dc_scenarios)]

        defined_scenarios <- unique(self$scenarios$Scenarios$Scenario_name)

        undefined_refs <- setdiff(dc_scenarios, defined_scenarios)
        if (length(undefined_refs) > 0) {
          self$errors$add(
            code = "E086",
            section = "Plots",
            sheet = "DataCombined",
            message = sprintf("Undefined scenario references: %s", paste(undefined_refs, collapse = ", "))
          )
        }
      }
    },

    #' Build JSON structure from current data
    build_json_structure = function() {
      json_data <- list()

      # Project configuration
      if (!is.null(self$project_settings)) {
        rows <- lapply(names(self$project_settings), function(prop) {
          list(Property = prop, Value = self$project_settings[[prop]], Description = "")
        })
        json_data$projectConfiguration <- list(
          column_names = c("Property", "Value", "Description"),
          rows = rows
        )
      }

      # Helper function to convert data frame to sheet structure
      df_to_sheet <- function(df) {
        if (is.null(df) || nrow(df) == 0) {
          return(list(column_names = names(df), rows = list()))
        }

        rows <- lapply(seq_len(nrow(df)), function(i) {
          row <- as.list(df[i, , drop = FALSE])
          # Convert NA to NULL for JSON
          lapply(row, function(x) if (is.na(x)) NULL else x)
        })

        list(column_names = names(df), rows = rows)
      }

      # Add each section
      if (!is.null(self$model_parameters)) {
        json_data$modelParameterSets <- lapply(self$model_parameters, df_to_sheet)
      }

      if (!is.null(self$individuals)) {
        json_data$Individuals <- lapply(self$individuals, df_to_sheet)
      }

      if (!is.null(self$populations)) {
        json_data$Populations <- lapply(self$populations, df_to_sheet)
      }

      if (!is.null(self$scenarios)) {
        json_data$Scenarios <- lapply(self$scenarios, df_to_sheet)
      }

      if (!is.null(self$applications)) {
        json_data$Applications <- lapply(self$applications, df_to_sheet)
      }

      if (!is.null(self$plots)) {
        json_data$Plots <- lapply(self$plots, df_to_sheet)
      }

      if (!is.null(self$populations_csv)) {
        json_data$populationsCSV <- lapply(self$populations_csv, df_to_sheet)
      }

      json_data
    }
  )
)


#' @title ValidationErrorCollection
#' @description R6 class for collecting validation errors with error codes
#' @export
ValidationErrorCollection <- R6::R6Class(
"ValidationErrorCollection",
  public = list(
    #' @field items List of error items
    items = NULL,

    #' @description Initialize error collection
    initialize = function() {
      self$items <- list()
    },

    #' @description Add a new error
    #' @param code Error code (e.g., "E001")
    #' @param section Section where error occurred
    #' @param sheet Sheet name (optional)
    #' @param message Error message
    add = function(code, section, message, sheet = NULL) {
      error <- list(
        code = code,
        section = section,
        sheet = sheet,
        message = message,
        timestamp = Sys.time()
      )
      self$items <- append(self$items, list(error))
      invisible(self)
    },

    #' @description Check if there are any errors
    #' @return Logical
    has_errors = function() {
      length(self$items) > 0
    },

    #' @description Get count of errors
    #' @return Integer
    count = function() {
      length(self$items)
    },

    #' @description Get all errors as a data frame
    #' @return Data frame of errors
    as_data_frame = function() {
      if (length(self$items) == 0) {
        return(data.frame(
          code = character(),
          section = character(),
          sheet = character(),
          message = character(),
          stringsAsFactors = FALSE
        ))
      }

      do.call(rbind, lapply(self$items, function(e) {
        data.frame(
          code = e$code,
          section = e$section,
          sheet = e$sheet %||% "",
          message = e$message,
          stringsAsFactors = FALSE
        )
      }))
    },

    #' @description Get errors by code prefix
    #' @param prefix Code prefix (e.g., "E01" for file errors)
    #' @return List of matching errors
    get_by_prefix = function(prefix) {
      Filter(function(e) startsWith(e$code, prefix), self$items)
    },

    #' @description Get errors by section
    #' @param section Section name
    #' @return List of matching errors
    get_by_section = function(section) {
      Filter(function(e) e$section == section, self$items)
    },

    #' @description Clear all errors
    clear = function() {
      self$items <- list()
      invisible(self)
    },

    #' @description Print errors
    print = function() {
      cat(sprintf("ValidationErrorCollection: %d errors\n", self$count()))
      for (e in self$items) {
        sheet_info <- if (!is.null(e$sheet)) sprintf(" [%s]", e$sheet) else ""
        cat(sprintf("  [%s] %s%s: %s\n", e$code, e$section, sheet_info, e$message))
      }
      invisible(self)
    }
  )
)


#' @title ValidationWarningCollection
#' @description R6 class for collecting validation warnings with warning codes
#' @export
ValidationWarningCollection <- R6::R6Class(
  "ValidationWarningCollection",
  public = list(
    #' @field items List of warning items
    items = NULL,

    #' @description Initialize warning collection
    initialize = function() {
      self$items <- list()
    },

    #' @description Add a new warning
    #' @param code Warning code (e.g., "W001")
    #' @param section Section where warning occurred
    #' @param sheet Sheet name (optional)
    #' @param message Warning message
    add = function(code, section, message, sheet = NULL) {
      warning <- list(
        code = code,
        section = section,
        sheet = sheet,
        message = message,
        timestamp = Sys.time()
      )
      self$items <- append(self$items, list(warning))
      invisible(self)
    },

    #' @description Check if there are any warnings
    #' @return Logical
    has_warnings = function() {
      length(self$items) > 0
    },

    #' @description Get count of warnings
    #' @return Integer
    count = function() {
      length(self$items)
    },

    #' @description Get all warnings as a data frame
    #' @return Data frame of warnings
    as_data_frame = function() {
      if (length(self$items) == 0) {
        return(data.frame(
          code = character(),
          section = character(),
          sheet = character(),
          message = character(),
          stringsAsFactors = FALSE
        ))
      }

      do.call(rbind, lapply(self$items, function(w) {
        data.frame(
          code = w$code,
          section = w$section,
          sheet = w$sheet %||% "",
          message = w$message,
          stringsAsFactors = FALSE
        )
      }))
    },

    #' @description Get warnings by code prefix
    #' @param prefix Code prefix (e.g., "W01")
    #' @return List of matching warnings
    get_by_prefix = function(prefix) {
      Filter(function(w) startsWith(w$code, prefix), self$items)
    },

    #' @description Get warnings by section
    #' @param section Section name
    #' @return List of matching warnings
    get_by_section = function(section) {
      Filter(function(w) w$section == section, self$items)
    },

    #' @description Clear all warnings
    clear = function() {
      self$items <- list()
      invisible(self)
    },

    #' @description Print warnings
    print = function() {
      cat(sprintf("ValidationWarningCollection: %d warnings\n", self$count()))
      for (w in self$items) {
        sheet_info <- if (!is.null(w$sheet)) sprintf(" [%s]", w$sheet) else ""
        cat(sprintf("  [%s] %s%s: %s\n", w$code, w$section, sheet_info, w$message))
      }
      invisible(self)
    }
  )
)


# Error Codes Reference
# =====================
# E001 - Configuration file not found
# E002 - Invalid file extension (not .json)
# E003 - JSON parse error
# E004 - Sheet parse error
# E010 - Missing projectConfiguration section
# E021 - Missing required column in Scenarios
# E022 - Duplicate scenario names
# E031 - Missing required column in IndividualBiometrics
# E032 - Duplicate IndividualId values
# E041 - Missing required column in Demographics
# E051 - Missing required column in modelParameterSets sheet
# E061 - Missing required column in Applications sheet
# E071 - Missing required column in DataCombined
# E072 - Invalid dataType value
# E073 - Missing required column in plotConfiguration
# E080 - Undefined IndividualId reference in Scenarios
# E082 - Undefined PopulationId reference in Scenarios
# E083 - Undefined ApplicationProtocol reference in Scenarios
# E084 - Undefined ModelParameterSheets reference in Scenarios
# E085 - Undefined DataCombinedName reference in plotConfiguration
# E086 - Undefined scenario reference in DataCombined
# E100 - Export error

# Warning Codes Reference
# =======================
# W005 - Empty sheet with no columns
# W010 - Empty projectConfiguration section
# W011 - Missing recommended property
# W020 - Missing Scenarios section
# W030 - Missing Individuals section
# W033 - Unknown Species value
# W040 - Missing Populations section
# W042 - Non-numeric value in numeric column
# W050 - Missing modelParameterSets section
# W060 - Missing Applications section
# W070 - Missing Plots section
# W074 - Unknown plotType value
# W081 - No parameter sheet for IndividualId
