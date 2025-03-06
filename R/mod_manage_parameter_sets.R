#' manage_parameter_sets UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_manage_parameter_sets_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      actionButton(ns("add_parameter"), "Add parameter set", icon = icon("plus")),
      actionButton(ns("remove_parameters"), "Remove parameter set", icon = icon("edit"))
    ),
    br()
  )
}

#' manage_parameter_sets Server Functions
#'
#' @noRd
mod_manage_parameter_sets_server <- function(id, r, tab_section, state_name, DROPDOWNS){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Show Dialog to Add Parameter
    observeEvent(input$add_parameter, {
      showModal(
        modalDialog(
          title = "Add Parameter",
          textInput(ns("parameter_name"), "Parameter Name"),
          footer = tagList(
            actionButton(ns("add_parameter_button"), "Add Parameter"),
            modalButton("Cancel")
          )
        )
      )
    })

    # Add Parameter
    observeEvent(input$add_parameter_button, {
      if(input$parameter_name %in% r$data[[tab_section]]$sheets){
        showModal(
          modalDialog(
            title = "Error",
            "Parameter already exists. Try another name.",
            footer = modalButton("OK")
          )
        )
      } else {
        r$data$create_new_sheet(tab_section, input$parameter_name)
        # Update global `DROPDOWN` options (sourced from sheet names)
        DROPDOWNS$applications$application_protocols <- r$data$applications$sheets |> unique()
        DROPDOWNS$scenarios$model_parameters <- r$data$models$sheets |> unique()
        removeModal()
      }
    })

    # Activate/Deactivate Edit Parameters mode
    observeEvent(input$remove_parameters, {
      r$states[[state_name]] <- (!r$states[[state_name]])
      # Update global `DROPDOWN` options (sourced from sheet names)
      DROPDOWNS$applications$application_protocols <- r$data$applications$sheets |> unique()
      DROPDOWNS$scenarios$model_parameters <- r$data$models$sheets |> unique()
      # Update Button Label
      updateActionButton(session, "remove_parameters",
                         label = if (r$states[[state_name]]) "Done" else "Remove parameter set")

    })

    # Handle all tabs removed
    observeEvent(r$data[[tab_section]]$sheets, {
      if(length(r$data[[tab_section]]$sheets) == 0){
        r$states[[state_name]] <- FALSE
        updateActionButton(session, "remove_parameters", label = "Remove parameter set")
      }
    })

  })
}

## To be copied in the UI
# mod_manage_parameter_sets_ui("manage_parameter_sets_1")

## To be copied in the server
# mod_manage_parameter_sets_server("manage_parameter_sets_1")
