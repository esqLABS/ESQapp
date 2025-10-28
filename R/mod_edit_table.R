#' tab_edit_table UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_edit_table_ui <- function(id) {
  ns <- NS(id)
  tagList(
    shiny::uiOutput(ns("edit_df"))
  )
}

#' tab_edit_table Server Functions
#'
#' @noRd
mod_edit_table_server <- function(id, r, tab_section, sheet, DROPDOWNS, METADATA = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$edit_df <- renderUI({

      data_init <- isolate(r$data[[tab_section]][[sheet]]$modified)
      if(is.null(data_init)) return(NULL)
      r$ui_triggers$selected_sheet # refresh key based on selected dropdown

      esqlabs.handsontable::scenario_table_Input(
        inputId = ns("scenario_table_input"),
        data = esqlabs.handsontable::prepare_js_data(
          data_init
        ),
        individual_id_options = isolate(DROPDOWNS$scenarios$individual_id),
        population_id_options = isolate(DROPDOWNS$scenarios$population_id),
        outputpath_id_options = isolate(DROPDOWNS$scenarios$outputpath_id),
        outputpath_id_alias_options = isolate(DROPDOWNS$scenarios$outputpath_id_alias),
        model_parameters_options = isolate(DROPDOWNS$scenarios$model_parameters),
        steatystatetime_unit_options = isolate(DROPDOWNS$scenarios$steadystatetime_unit),
        model_files_options = isolate(DROPDOWNS$scenarios$model_files),
        species_options = isolate(DROPDOWNS$individuals$species_options),
        population_options = isolate(DROPDOWNS$individuals$specieshuman_options),
        gender_options = isolate(DROPDOWNS$individuals$gender_options),
        weight_unit_options = isolate(DROPDOWNS$populations$weight_unit),
        height_unit_options = isolate(DROPDOWNS$populations$height_unit),
        bmi_unit_options = isolate(DROPDOWNS$populations$bmi_unit),
        datatype_options = isolate(DROPDOWNS$plots$datatype_options),
        scenario_options = isolate(DROPDOWNS$plots$scenario_options),
        datacombinedname_options = isolate(DROPDOWNS$plots$datacombinedname_options),
        plottype_options = isolate(DROPDOWNS$plots$plottype_options),
        axisscale_options = isolate(DROPDOWNS$plots$axisscale_options),
        aggregation_options = isolate(DROPDOWNS$plots$aggregation_options),
        path_options = isolate(DROPDOWNS$plots$path_options),
        application_protocol_options = isolate(DROPDOWNS$applications$application_protocols),
        plotgridnames_options = isolate(DROPDOWNS$plots$plotgridnames_options),
        plotids_options = isolate(DROPDOWNS$plots$plotids_options),
        datasets_options = isolate(DROPDOWNS$plots$datasets_options),
        loaddata_metadata = METADATA$plots$loaddata_metadata,
        sheet_name = sheet,
        column_headers = (
          colnames(
            data_init
          )
        )
      )

    })

    observeEvent(input$scenario_table_input_edited, {
      # Update data without re-rendering UI
      r$data[[tab_section]][[sheet]]$modified <- esqlabs.handsontable::parse_js_data(
        input$scenario_table_input_edited
      )

      # Column names
      column_names_header <- (
        colnames(
          isolate(r$data[[tab_section]][[sheet]]$modified)
        )
      )

      # Populate dropdowns
      DROPDOWNS$scenarios$individual_id <- r$data$individuals$IndividualBiometrics$modified$IndividualId
      DROPDOWNS$scenarios$population_id <- r$data$populations$Demographics$modified$PopulationName
      DROPDOWNS$scenarios$outputpath_id <- r$data$scenarios$OutputPaths$modified$OutputPathId
      DROPDOWNS$scenarios$outputpath_id_alias <- setNames(
        as.list(as.character(r$data$scenarios$OutputPaths$modified$OutputPath)),
        r$data$scenarios$OutputPaths$modified$OutputPathId
      )
      DROPDOWNS$plots$scenario_options <- r$data$scenarios$Scenarios$modified$Scenario_name |> unique()
      DROPDOWNS$plots$path_options <- r$data$scenarios$OutputPaths$modified$OutputPath |> unique()
      DROPDOWNS$plots$datacombinedname_options <- r$data$plots$DataCombined$modified$DataCombinedName |> unique()
      DROPDOWNS$plots$plotgridnames_options <- r$data$plots$plotGrids$modified$name |> unique()
      DROPDOWNS$plots$plotids_options <- r$data$plots$plotConfiguration$modified$plotID |> unique()

      esqlabs.handsontable::updateScenario_table_Input(
        session = getDefaultReactiveDomain(),
        inputId = "scenario_table_input",
        value = input$scenario_table_input_edited,
        configuration = list(
          individual_id_dropdown = DROPDOWNS$scenarios$individual_id,
          population_id_dropdown = DROPDOWNS$scenarios$population_id,
          outputpath_id_dropdown = DROPDOWNS$scenarios$outputpath_id,
          outputpath_id_alias_dropdown = DROPDOWNS$scenarios$outputpath_id_alias,
          model_parameters_dropdown = DROPDOWNS$scenarios$model_parameters,
          steatystatetime_unit_dropdown = DROPDOWNS$scenarios$steadystatetime_unit,
          model_files_dropdown = DROPDOWNS$scenarios$model_files,
          species_option_dropdown = DROPDOWNS$individuals$species_options,
          population_option_dropdown = DROPDOWNS$individuals$specieshuman_options,
          gender_option_dropdown = DROPDOWNS$individuals$gender_options,
          weight_unit_dropdown = DROPDOWNS$populations$weight_unit,
          height_unit_dropdown = DROPDOWNS$populations$height_unit,
          bmi_unit_dropdown = DROPDOWNS$populations$bmi_unit,
          datatype_option_dropdown = DROPDOWNS$plots$datatype_options,
          scenario_option_dropdown = DROPDOWNS$plots$scenario_options,
          datacombinedname_option_dropdown = DROPDOWNS$plots$datacombinedname_options,
          plottype_option_dropdown = DROPDOWNS$plots$plottype_options,
          axisscale_option_dropdown = DROPDOWNS$plots$axisscale_options,
          aggregation_option_dropdown = DROPDOWNS$plots$aggregation_options,
          path_option_dropdown = DROPDOWNS$plots$path_options,
          application_protocol_dropdown = DROPDOWNS$applications$application_protocols,
          plotgridnames_option_dropdown = DROPDOWNS$plots$plotgridnames_options,
          plotids_option_dropdown = DROPDOWNS$plots$plotids_options,
          datasets_option_dropdown = DROPDOWNS$plots$datasets_options,
          loaddata_metadata = METADATA$plots$loaddata_metadata,
          sheet = sheet,
          shiny_el_id_name = ns("scenario_table_input"),
          column_headers = column_names_header
        )
      )

      # Add/Remove/Rename individual_id sheet
      if (tab_section == "individuals") {
        if (isTruthy(input$scenario_table_input_individual_event)) {
          # The input$scenario_table_input_individual_event can have the following possible values:
          # 1. {"eventType": "individualId_added", "individualIdName": "<new_name>"}
          #    - This indicates that a new individual ID has been added.
          #    - `individualIdName` will contain the name of the newly added individual.
          #
          # 2. {"eventType": "individualId_removed", "individualIdName": "<removed_name>"}
          #    - This indicates that an individual ID has been removed.
          #    - `individualIdName` will contain the name of the individual that was removed.
          #
          # 3. {"eventType": "individualId_renamed", "individualIdOldName": "<old_name>", "individualIdNewName": "<new_name>"}
          #    - This indicates that an individual ID has been renamed.
          #    - `individualIdOldName` will contain the old name of the individual.
          #    - `individualIdNewName` will contain the new name of the individual.

          event_recorded <- input$scenario_table_input_individual_event |>
            jsonlite::fromJSON()

          if (event_recorded$eventType == "individualId_added") {
            r$data$create_new_sheet(
              config_name = tab_section,
              sheet_name = event_recorded$individualIdName
            )
          }

          if (event_recorded$eventType == "individualId_removed") {
            r$data$remove_sheet(
              config_name = tab_section,
              sheet_name = event_recorded$individualIdName
            )
          }

          if (event_recorded$eventType == "individualId_renamed") {
            r$data$rename_individual_sheet(
              config_name = tab_section,
              old_sheet_name = event_recorded$individualIdOldName,
              new_sheet_name = event_recorded$individualIdNewName
            )
          }
        }
      }
    })
  })
}

## To be copied in the UI
# mod_edit_table_ui("tab_scenario_1")

## To be copied in the server
# mod_edit_table_server("tab_scenario_1")
