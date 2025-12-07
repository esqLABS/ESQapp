#' export UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_export_ui <- function(id) {
  ns <- NS(id)
  tagList(
    actionButton(ns("export"), "Export", class = "btn-dark", disabled = TRUE),
    actionButton(ns("export_json"), "Export JSON", class = "btn-secondary", disabled = TRUE)
  )
}

#' export Server Functions
#'
#' @noRd
mod_export_server <- function(id, r, configuration_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Enable the export buttons when the configuration file is loaded first time
    observeEvent(configuration_path(),
      {
        updateActionButton(session, inputId = "export", disabled = FALSE)
        updateActionButton(session, inputId = "export_json", disabled = FALSE)
      },
      once = TRUE
    )


    # Listen to the export button
    observeEvent(input$export, {
      message("exporting data")

      export_success <- TRUE # Track overall success

      for (config_file in r$data$get_config_files()) {
        if (!golem::app_prod()) {
          export_path <- paste0(fs::path_ext_remove(r$data[[config_file]]$file_path), "_copy.xlsx")
        } else {
          export_path <- r$data[[config_file]]$file_path
        }

        message("Exporting modified", config_file, " to ", export_path)

        sheet_list <- list()

        for (sheet in r$data[[config_file]]$sheets) {
          df <- r$data[[config_file]][[sheet]]$modified
          # Get columns for this sheet (if any dropdown)
          dropdown_cols <- DROPDOWN_COLUMN_TYPE_LIST[[config_file]][[sheet]]
          # replace "--NONE--" with NA if it exists
          if (!is.null(dropdown_cols)) {
            df[dropdown_cols] <- lapply(df[dropdown_cols], function(col) {
              replace(col, col == "--NONE--", NA)
            })
          }
          # Convert numeric columns from text to numeric
          numeric_cols <- NUMERIC_COLUMN_TYPE_LIST[[config_file]][[sheet]]
          if (!is.null(numeric_cols)) {
            # Only convert columns that exist in the dataframe
            existing_numeric_cols <- intersect(numeric_cols, names(df))
            if (length(existing_numeric_cols) > 0) {
              df[existing_numeric_cols] <- suppressWarnings(
                lapply(df[existing_numeric_cols], function(col) {
                  as.numeric(as.character(col))
                })
              )
            }
          }
          # Save data to the `sheet_list`
          sheet_list[[sheet]] <- df
        }

        # Try exporting and catch any errors
        tryCatch(
          {
            rio::export(
              x = sheet_list,
              file = export_path
            )
            message("Export successful: ", export_path)
          },
          error = function(e) {
            message("Error exporting ", config_file, ": File might be open or locked. Please close it and try again.")
            r$states$modal_message <- list(
              status = "Error: XLSX file might be open",
              message = paste0(
                "File might be open or locked. Please close ", fs::path_file(export_path),
                " and try again."
              )
            )
            export_success <<- FALSE # Mark failure
          }
        )
      }

      # Set success message if no errors occurred
      if (export_success) {
        r$states$modal_message <- list(
          status = "Success",
          message = "Export completed successfully!"
        )
      }
    })

    # Listen to the export JSON button
    observeEvent(input$export_json, {
      message("Exporting data to JSON")

      tryCatch({
        # Determine export path
        if (!is.null(r$config$json_config)) {
          # If loaded from JSON, use same path with _copy suffix in dev mode
          base_path <- r$config$json_config$file_path
        } else {
          # If loaded from Excel, create JSON next to the original config
          base_path <- r$data$scenarios$file_path
          base_path <- gsub("\\.xlsx$", ".json", base_path, ignore.case = TRUE)
        }

        if (!golem::app_prod()) {
          export_path <- gsub("\\.json$", "_copy.json", base_path, ignore.case = TRUE)
        } else {
          export_path <- base_path
        }

        message("Exporting to JSON: ", export_path)

        # Build JSON structure from current data (pass r$config to preserve settings)
        json_data <- build_json_from_data(r$data, r$config)

        # Write JSON file
        json_string <- jsonlite::toJSON(json_data, pretty = TRUE, auto_unbox = TRUE, null = "null")
        writeLines(json_string, export_path, useBytes = TRUE)

        r$states$modal_message <- list(
          status = "Success",
          message = sprintf("JSON export completed successfully!\nFile: %s", basename(export_path))
        )

      }, error = function(e) {
        message("Error exporting JSON: ", conditionMessage(e))
        r$states$modal_message <- list(
          status = "Error exporting JSON",
          message = sprintf("Failed to export JSON: %s", conditionMessage(e))
        )
      })
    })
  })
}


#' Build JSON structure from DataStructure
#'
#' @description Converts the current data in DataStructure to JSON format
#' @param data DataStructure object
#' @param r_config Optional r$config object containing json_config reference
#' @return List structure suitable for JSON export
#' @noRd
build_json_from_data <- function(data, r_config = NULL) {
  json_data <- list()

  # Helper to convert data frame to sheet structure
  df_to_sheet <- function(df) {
    if (is.null(df)) {
      return(list(column_names = character(0), rows = list()))
    }

    if (nrow(df) == 0) {
      return(list(column_names = names(df), rows = list()))
    }

    rows <- lapply(seq_len(nrow(df)), function(i) {
      row <- as.list(df[i, , drop = FALSE])
      # Convert NA to NULL for JSON, and ensure all values are character
      lapply(row, function(x) {
        if (is.null(x) || (length(x) == 1 && is.na(x))) {
          NULL
        } else if (is.character(x) && x == "--NONE--") {
          NULL
        } else {
          as.character(x)
        }
      })
    })

    list(column_names = names(df), rows = rows)
  }

  # Helper to process numeric columns before export
  process_sheet_data <- function(df, config_file, sheet_name) {
    if (is.null(df)) return(df)

    # Get dropdown columns for this sheet
    dropdown_cols <- DROPDOWN_COLUMN_TYPE_LIST[[config_file]][[sheet_name]]
    if (!is.null(dropdown_cols)) {
      existing_cols <- intersect(dropdown_cols, names(df))
      if (length(existing_cols) > 0) {
        df[existing_cols] <- lapply(df[existing_cols], function(col) {
          replace(col, col == "--NONE--", NA)
        })
      }
    }

    # Convert numeric columns
    numeric_cols <- NUMERIC_COLUMN_TYPE_LIST[[config_file]][[sheet_name]]
    if (!is.null(numeric_cols)) {
      existing_cols <- intersect(numeric_cols, names(df))
      if (length(existing_cols) > 0) {
        df[existing_cols] <- suppressWarnings(
          lapply(df[existing_cols], function(col) {
            as.character(as.numeric(as.character(col)))
          })
        )
      }
    }

    df
  }

  # Map internal names to JSON section names
  section_map <- list(
    scenarios = "Scenarios",
    individuals = "Individuals",
    populations = "Populations",
    models = "modelParameterSets",
    applications = "Applications",
    plots = "Plots"
  )

  # Process each configuration section
  for (config_file in data$get_config_files()) {
    sheets <- data[[config_file]]$sheets

    if (!is.null(sheets) && length(sheets) > 0 && !all(is.na(sheets))) {
      section_name <- section_map[[config_file]]
      json_data[[section_name]] <- list()

      for (sheet_name in sheets) {
        if (!is.null(data[[config_file]][[sheet_name]]) &&
            !is.null(data[[config_file]][[sheet_name]]$modified)) {

          df <- data[[config_file]][[sheet_name]]$modified
          df <- process_sheet_data(df, config_file, sheet_name)
          json_data[[section_name]][[sheet_name]] <- df_to_sheet(df)
        }
      }
    }
  }

  # Add projectConfiguration section
  # If we have the original JSON config, preserve its settings
  if (!is.null(r_config) && !is.null(r_config$json_config) &&
      !is.null(r_config$json_config$project_settings)) {

    settings <- r_config$json_config$project_settings
    rows <- lapply(names(settings), function(prop) {
      list(
        Property = prop,
        Value = settings[[prop]] %||% "",
        Description = ""
      )
    })

    json_data$projectConfiguration <- list(
      column_names = c("Property", "Value", "Description"),
      rows = rows
    )
  } else {
    # Create default projectConfiguration
    json_data$projectConfiguration <- list(
      column_names = c("Property", "Value", "Description"),
      rows = list(
        list(Property = "modelFolder", Value = "Models/Simulations/", Description = "Path to the folder with pkml simulation files"),
        list(Property = "configurationsFolder", Value = "Configurations/", Description = "Path to the folder with configuration files"),
        list(Property = "modelParamsFile", Value = "ModelParameters.xlsx", Description = "Name of the model parameters file"),
        list(Property = "individualsFile", Value = "Individuals.xlsx", Description = "Name of the individuals file"),
        list(Property = "populationsFile", Value = "Populations.xlsx", Description = "Name of the populations file"),
        list(Property = "populationsFolder", Value = "PopulationsCSV", Description = "Name of the folder containing population CSV files"),
        list(Property = "scenariosFile", Value = "Scenarios.xlsx", Description = "Name of the scenarios file"),
        list(Property = "applicationsFile", Value = "Applications.xlsx", Description = "Name of the applications file"),
        list(Property = "plotsFile", Value = "Plots.xlsx", Description = "Name of the plots file"),
        list(Property = "dataFolder", Value = "Data/", Description = "Path to the folder with experimental data"),
        list(Property = "dataFile", Value = "", Description = "Name of the experimental data file"),
        list(Property = "dataImporterConfigurationFile", Value = "", Description = "Name of data importer configuration file"),
        list(Property = "outputFolder", Value = "Results/", Description = "Path to the folder for output files")
      )
    )
  }

  # Reorder sections to match expected JSON structure
  ordered_sections <- c(
    "projectConfiguration",
    "modelParameterSets",
    "Individuals",
    "Populations",
    "Scenarios",
    "Applications",
    "Plots"
  )

  ordered_json <- list()
  for (section in ordered_sections) {
    if (!is.null(json_data[[section]])) {
      ordered_json[[section]] <- json_data[[section]]
    }
  }

  # Add any remaining sections not in the ordered list
  for (section in names(json_data)) {
    if (!section %in% ordered_sections) {
      ordered_json[[section]] <- json_data[[section]]
    }
  }

  ordered_json
}


## To be copied in the UI
# mod_export_ui("export_1")

## To be copied in the server
# mod_export_server("export_1")
