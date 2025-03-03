#' table_tab UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_table_tab_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("ui")) |> shinycssloaders::withSpinner(type = 2, color.background = "#ffffff", color = "#2bc1ca")
  )
}

#' table_tab Server Functions
#'
#' @noRd
mod_table_tab_server <- function(id, r, tab_section, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    r$states$edit_mode_models <- FALSE
    r$states$edit_mode_applications <- FALSE

    output$ui <- renderUI({
      req(r$data[[tab_section]]$sheets)

      nav_panel_list <- list()

      for (sheet in r$data[[tab_section]]$sheets) {

        nav_panel_list[[length(nav_panel_list) + 1]] <-
          nav_panel(
            title = div(
              sheet,
              tagList(
                if (r$states$edit_mode_models && tab_section == "models") {
                  cross_btn(sheet, ns)
                },
                if (r$states$edit_mode_applications && tab_section == "applications") {
                  cross_btn(sheet, ns)
                }
              ),
              style = "display: flex; align-items: center; gap: 5px; position: relative;"
            ),
            br(),
            mod_edit_table_ui(id = ns(paste("tab", sheet, sep = "_")))
          )
      }

      return(navset_pill(!!!nav_panel_list))
    })

    observe({
      req(r$data[[tab_section]]$sheets)
      req(DROPDOWNS)

      for (sheet in r$data[[tab_section]]$sheets) {
        do.call(mod_edit_table_server, args = list(
          id = paste("tab", sheet, sep = "_"),
          r = r,
          tab_section = tab_section,
          sheet = sheet,
          DROPDOWNS = DROPDOWNS
        ))
      }

    })


    # Delete sheet from parameters set
    observeEvent(input$remove_parameter_name, {
      r$data$remove_sheet(
        config_name = tab_section,
        sheet_name = input$remove_parameter_name
      )
    })

  })
}

## To be copied in the UI
# mod_table_tab_ui("table_tab_1")

## To be copied in the server
# mod_table_tab_server("table_tab_1")
