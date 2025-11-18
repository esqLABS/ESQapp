#' Dropdown Population Utilities
#'
#' @description Configuration-driven system for populating dropdown menus
#' from imported Excel data. Eliminates repetitive code and makes dropdown
#' dependencies explicit.

#' Populate Dropdowns from Configuration
#'
#' @description Populates dropdown options based on a configuration map.
#' Automatically handles file existence checks, null checks, and data extraction.
#'
#' @param dropdowns The DROPDOWNS reactive values object to populate
#' @param data The r$data object containing imported configuration data
#' @param config A list defining dropdown mappings (see examples)
#'
#' @return NULL (modifies dropdowns in place)
#'
#' @examples
#' \dontrun{
#' config <- list(
#'   scenarios = list(
#'     individual_id = list(
#'       file = "individuals",
#'       sheet = "IndividualBiometrics",
#'       column = "IndividualId"
#'     )
#'   )
#' )
#' populate_dropdowns(DROPDOWNS, r$data, config)
#' }
#'
#' @export
populate_dropdowns <- function(dropdowns, data, config) {
  for (dropdown_group in names(config)) {
    for (dropdown_name in names(config[[dropdown_group]])) {
      dropdown_spec <- config[[dropdown_group]][[dropdown_name]]

      # Extract specification
      file_name <- dropdown_spec$file
      sheet_name <- dropdown_spec$sheet
      column_name <- dropdown_spec$column
      extract_type <- dropdown_spec$extract  # e.g., "sheets", "unique"
      transform <- dropdown_spec$transform   # Optional transformation function

      # Check if file exists
      file_path <- data[[file_name]]$file_path
      if (is.null(file_path) || is.na(file_path) || !file.exists(file_path)) {
        next
      }

      # Handle different extraction types
      if (!is.null(extract_type)) {
        if (extract_type == "sheets") {
          # Extract sheet names
          dropdowns[[dropdown_group]][[dropdown_name]] <- data[[file_name]]$sheets
        }
      } else if (!is.null(sheet_name) && !is.null(column_name)) {
        # Extract column from sheet
        sheet_data <- data[[file_name]][[sheet_name]]
        if (is.null(sheet_data) || is.null(sheet_data$modified)) {
          next
        }

        column_data <- sheet_data$modified[[column_name]]
        if (is.null(column_data)) {
          next
        }

        # Apply transformation if specified
        if (!is.null(transform)) {
          column_data <- transform(column_data)
        } else {
          # Default: get unique values
          column_data <- unique(column_data)
        }

        dropdowns[[dropdown_group]][[dropdown_name]] <- column_data
      }
    }
  }

  invisible(NULL)
}

#' Create Named List Transformation
#'
#' @description Helper function to create a named list transformation for dropdowns
#'
#' @param names_col The column to use as names
#' @param values_col The column to use as values
#'
#' @return A transformation function
#'
#' @export
named_list_transform <- function(names_col, values_col) {
  function(data) {
    setNames(
      as.list(as.character(data[[values_col]])),
      data[[names_col]]
    )
  }
}

#' Get Default Dropdown Configuration
#'
#' @description Returns the default dropdown configuration for the application.
#' This configuration defines which dropdowns pull data from which files/sheets/columns.
#'
#' @return A list defining dropdown mappings
#'
#' @export
get_dropdown_config <- function() {
  list(
    scenarios = list(
      individual_id = list(
        file = "individuals",
        sheet = "IndividualBiometrics",
        column = "IndividualId"
      ),
      population_id = list(
        file = "populations",
        sheet = "Demographics",
        column = "PopulationName"
      ),
      outputpath_id = list(
        file = "scenarios",
        sheet = "OutputPaths",
        column = "OutputPathId"
      ),
      model_parameters = list(
        file = "models",
        extract = "sheets"
      )
    ),
    plots = list(
      path_options = list(
        file = "scenarios",
        sheet = "OutputPaths",
        column = "OutputPath"
      ),
      scenario_options = list(
        file = "scenarios",
        sheet = "Scenarios",
        column = "Scenario_name"
      ),
      datacombinedname_options = list(
        file = "plots",
        sheet = "DataCombined",
        column = "DataCombinedName"
      ),
      plotgridnames_options = list(
        file = "plots",
        sheet = "plotGrids",
        column = "name"
      ),
      plotids_options = list(
        file = "plots",
        sheet = "plotConfiguration",
        column = "plotID"
      )
    ),
    applications = list(
      application_protocols = list(
        file = "applications",
        extract = "sheets"
      )
    )
  )
}

#' Populate Special Dropdowns
#'
#' @description Handles special dropdown cases that don't fit the standard pattern
#' (e.g., outputpath_id_alias which creates a named list)
#'
#' @param dropdowns The DROPDOWNS reactive values object to populate
#' @param data The r$data object containing imported configuration data
#'
#' @return NULL (modifies dropdowns in place)
#'
#' @export
populate_special_dropdowns <- function(dropdowns, data) {
  # Handle outputpath_id_alias (named list mapping)
  if (!is.null(data$scenarios$OutputPaths) &&
      !is.null(data$scenarios$OutputPaths$modified)) {
    output_paths <- data$scenarios$OutputPaths$modified

    if (!is.null(output_paths$OutputPathId) && !is.null(output_paths$OutputPath)) {
      dropdowns$scenarios$outputpath_id_alias <- setNames(
        as.list(as.character(output_paths$OutputPath)),
        output_paths$OutputPathId
      )
    }
  }

  invisible(NULL)
}
