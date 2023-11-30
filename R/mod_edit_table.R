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
    datamods::edit_data_ui(ns("edit_df"))
  )
}

#' tab_edit_table Server Functions
#'
#' @noRd
mod_edit_table_server <- function(id, r, tab_section, sheet) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    edited_data <- datamods::edit_data_server(
      id = "edit_df",
      download_excel = FALSE,
      download_csv = FALSE,
      data_r = reactive(r$data[[tab_section]][[sheet]]$df$modified),
      reactable_options = list(
        searchable = TRUE,
        pagination = FALSE
      )
    )

    # When data is edited, update the modified copy of data in r$data
    observe({
      req(edited_data())

      temp_data <- edited_data()

      for (column in names(temp_data)) {

        column_data <- r$data[[tab_section]][[sheet]]$columns[[column]]

        if (!is.null(column_data$reactive_levels)) {
          reactive_levels <- column_data$reactive_levels()

          temp_data[[column]] <- factor(
            temp_data[[column]],
            levels = sort(unique(c(
              reactive_levels,
              as.character(temp_data[[column]])
            )))
          )
        }
      }

      r$data[[tab_section]][[sheet]]$df$modified <- temp_data
    })
  })
}

## To be copied in the UI
# mod_edit_table_ui("tab_scenario_1")

## To be copied in the server
# mod_edit_table_server("tab_scenario_1")
