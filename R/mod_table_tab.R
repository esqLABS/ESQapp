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

    r$states$edit_mode_models <- NULL # Models (Parameter sets) tab
    r$states$edit_mode_applications <- NULL # Applications tab
    r$states$current_sheet_selected_models <- NULL
    r$states$current_sheet_selected_applications <- NULL
    r$states$current_sheet_selected_individuals <- NULL
    r$states$current_sheet_selected_populations <- NULL


    # Render the UI (tabs) for the tab section
    output$ui <- renderUI({
      req(r$data[[tab_section]]$sheets)

      if (tab_section %in% c("models", "applications", "individuals", "populations")) {
        sheets <- r$data[[tab_section]]$sheets
        valid_sheets <- is.character(sheets) && length(sheets) > 0 && any(nzchar(sheets))

        if (!valid_sheets) {
          sheets <- NULL
          selected_sheet <- NULL
          if (tab_section == "models") {
            r$states$current_sheet_selected_models <- NULL
          }
          if(tab_section == "applications") {
            r$states$current_sheet_selected_applications <- NULL
          }
          if(tab_section == "individuals") {
            r$states$current_sheet_selected_individuals <- NULL
          }
          if(tab_section == "populations") {
            r$states$current_sheet_selected_populations <- NULL
          }
        } else {

          if (tab_section %in% c("individuals", "populations")) {
            selected_sheet <- head(sheets, 1)
          } else {
            selected_sheet <- tail(sheets, 1)
          }

          if (tab_section == "models") {
            r$states$current_sheet_selected_models <- selected_sheet
          }
          if(tab_section == "applications") {
            r$states$current_sheet_selected_applications <- selected_sheet
          }
          if(tab_section == "individuals") {
            r$states$current_sheet_selected_individuals <- selected_sheet
          }
          if(tab_section == "populations") {
            r$states$current_sheet_selected_populations <- selected_sheet
          }
        }

        tags_ <- tagList(
          selectInput(ns("selected_sheet"), "Select parameter set", choices = sheets, selected = selected_sheet),
          uiOutput(ns("selected_sheet_ui"))
        )
        return(tags_)
      } else {
        nav_panel_list <- list()

        for (sheet in r$data[[tab_section]]$sheets) {

          nav_panel_list[[length(nav_panel_list) + 1]] <-
            nav_panel(
              title = div(
                sheet,
                tagList(
                  if(tab_section %in% c("models", "applications", "individuals", "populations")) {
                    next
                  }
                ),
                style = "display: flex; align-items: center; gap: 5px; position: relative;"
              ),
              br(),
              if(tab_section == "plots" && sheet %in% c("dataTypes", "plotTypes", "ObservedDataNames")) {
                next
              } else {
                mod_edit_table_ui(id = ns(paste("tab", sheet, sep = "_")))
              }
            )
        }

        return(navset_pill(!!!nav_panel_list))

      }

    })

    # Render the UI for the selected sheet Related to "Models" (Paramet Sets) and "Applications"
    output$selected_sheet_ui <- renderUI({
      selected <- switch(
        tab_section,
        "models"       = r$states$current_sheet_selected_models,
        "applications" = r$states$current_sheet_selected_applications,
        "individuals"  = r$states$current_sheet_selected_individuals,
        "populations"  = r$states$current_sheet_selected_populations
      )
      req(selected)
      mod_edit_table_ui(id = ns(paste("tab", selected, sep = "_")))
    })

    # Observe the selected sheet and update the reactive state
    observeEvent(input$selected_sheet, {
      if (tab_section == "models") {
        r$states$current_sheet_selected_models <- input$selected_sheet
      }
      if (tab_section == "applications") {
        r$states$current_sheet_selected_applications <- input$selected_sheet
      }
      if (tab_section == "individuals") {
        r$states$current_sheet_selected_individuals <- input$selected_sheet
      }
      if (tab_section == "populations") {
        r$states$current_sheet_selected_populations <- input$selected_sheet
      }
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


    # Delete sheet for "Models" (Parameter sets)
    observeEvent(r$states$edit_mode_models, {
      r$data$remove_sheet(
        config_name = r$states$edit_mode_models$tab_section,
        sheet_name = r$states$current_sheet_selected_models
      )
      r$states$edit_mode_models <- NULL
    })

    # Delete sheet for "Applications"
    observeEvent(r$states$edit_mode_applications, {
      r$data$remove_sheet(
        config_name = r$states$edit_mode_applications$tab_section,
        sheet_name = r$states$current_sheet_selected_applications
      )
      r$states$edit_mode_applications <- NULL
    })

  })
}

## To be copied in the UI
# mod_table_tab_ui("table_tab_1")

## To be copied in the server
# mod_table_tab_server("table_tab_1")
