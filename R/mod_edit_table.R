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
  # datamods::edit_data_ui(ns("edit_df"))
    shiny::uiOutput(ns("edit_df"))
  )
}

#' tab_edit_table Server Functions
#'
#' @noRd
mod_edit_table_server <- function(id, r, tab_section, sheet, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$edit_df <- renderUI({

      # browser()

      esqlabs.handsontable::scenario_table_Input(
        inputId = ns("scenario_table_input"),
        data = esqlabs.handsontable::prepare_js_data(
          isolate(r$data[[tab_section]][[sheet]]$modified)
        ),
        individual_id_options        = DROPDOWNS$scenarios$individual_id,
        population_id_options        = DROPDOWNS$scenarios$population_id,
        outputpath_id_options        = DROPDOWNS$scenarios$outputpath_id,
        steatystatetime_unit_options = DROPDOWNS$scenarios$steadystatetime_unit,
        species_options              = DROPDOWNS$individuals$species_options,
        population_options           = DROPDOWNS$individuals$specieshuman_options,
        gender_options               = DROPDOWNS$individuals$gender_options,
        weight_unit_options          = DROPDOWNS$populations$weight_unit,
        height_unit_options          = DROPDOWNS$populations$height_unit,
        bmi_unit_options             = DROPDOWNS$populations$bmi_unit,
        datatype_options             = DROPDOWNS$plots$datatype_options,
        scenario_options             = DROPDOWNS$plots$scenario_options,
        datacombinedname_options     = DROPDOWNS$plots$datacombinedname_options,
        plottype_options             = DROPDOWNS$plots$plottype_options,
        axisscale_options            = DROPDOWNS$plots$axisscale_options,
        aggregation_options          = DROPDOWNS$plots$aggregation_options,
        path_options                 = DROPDOWNS$plots$path_options,
        sheet_name                   = sheet
      )
    })

    observeEvent(input$scenario_table_input_edited, {
      # print(
      #   esqlabs.handsontable::parse_js_data(
      #     input$scenario_table_input_edited
      #   )
      # )

      r$data[[tab_section]][[sheet]]$modified <- esqlabs.handsontable::parse_js_data(
                                                    input$scenario_table_input_edited
                                                 )

      # Populate dropdowns
      DROPDOWNS$scenarios$individual_id        <- r$data$individuals$IndividualBiometrics$modified$IndividualId
      DROPDOWNS$scenarios$population_id        <- r$data$populations$Demographics$modified$PopulationName
      DROPDOWNS$scenarios$outputpath_id        <- r$data$scenarios$OutputPaths$modified$OutputPathId
      DROPDOWNS$plots$scenario_options         <- r$data$scenarios$Scenarios$modified$Scenario_name |> unique()
      DROPDOWNS$plots$path_options             <- r$data$scenarios$OutputPaths$modified$OutputPath |> unique()
      DROPDOWNS$plots$datacombinedname_options <- r$data$plots$DataCombined$modified$DataCombinedName |> unique()


      esqlabs.handsontable::updateScenario_table_Input(session = getDefaultReactiveDomain(),
                         inputId = 'scenario_table_input',
                         value = input$scenario_table_input_edited,
                         configuration = list(
                           individual_id_dropdown        = DROPDOWNS$scenarios$individual_id,
                           population_id_dropdown        = DROPDOWNS$scenarios$population_id,
                           outputpath_id_dropdown        = DROPDOWNS$scenarios$outputpath_id,
                           steatystatetime_unit_dropdown = DROPDOWNS$scenarios$steadystatetime_unit,
                           species_option_dropdown              = DROPDOWNS$individuals$species_options,
                           population_option_dropdown           = DROPDOWNS$individuals$specieshuman_options,
                           gender_option_dropdown               = DROPDOWNS$individuals$gender_options,
                           weight_unit_dropdown          = DROPDOWNS$populations$weight_unit,
                           height_unit_dropdown          = DROPDOWNS$populations$height_unit,
                           bmi_unit_dropdown             = DROPDOWNS$populations$bmi_unit,
                           datatype_option_dropdown             = DROPDOWNS$plots$datatype_options,
                           scenario_option_dropdown             = DROPDOWNS$plots$scenario_options,
                           datacombinedname_option_dropdown     = DROPDOWNS$plots$datacombinedname_options,
                           plottype_option_dropdown             = DROPDOWNS$plots$plottype_options,
                           axisscale_option_dropdown            = DROPDOWNS$plots$axisscale_options,
                           aggregation_option_dropdown          = DROPDOWNS$plots$aggregation_options,
                           path_option_dropdown                 = DROPDOWNS$plots$path_options,
                           sheet                        = sheet,
                           shiny_el_id_name = ns("scenario_table_input")
                         )
      )


    })

    # edited_data <- datamods::edit_data_server(
    #   id = "edit_df",
    #   download_excel = FALSE,
    #   download_csv = FALSE,
    #   data_r = reactive(r$data[[tab_section]][[sheet]]$original),
    #   reactable_options = list(
    #     searchable = TRUE,
    #     pagination = FALSE,
    #     resizable = TRUE
    #   )
    # )

    # When data is edited, update the modified copy of data in r$data
    # observe({
    #   req(edited_data())
    #
    #   print(edited_data())
    #
    #   r$data[[tab_section]][[sheet]]$modified <- edited_data()
    # })
  })
}

## To be copied in the UI
# mod_edit_table_ui("tab_scenario_1")

## To be copied in the server
# mod_edit_table_server("tab_scenario_1")
