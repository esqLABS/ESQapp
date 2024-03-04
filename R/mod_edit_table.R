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
mod_edit_table_server <- function(id, r, tab_section, sheet) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns


    output$edit_df <- renderUI({

      esqlabs.handsontable::scenario_table_Input(
        inputId = ns("scenario_table_input"),
        data = esqlabs.handsontable::prepare_js_data(
          r$data[[tab_section]][[sheet]]$original
        ),
        individual_id_options = c("ind1", "ind2", "ind3"),
        # individual_id_options = r$data$individuals$IndividualBiometrics$modified$IndividualId,
        population_id_options = c("pop1", "pop2", "pop3"),
        sheet_name = sheet
      )
    })

    observeEvent(input$scenario_table_edit, {
      print(
        esqlabs.handsontable::parse_js_data(
          input$scenario_table_edit
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
