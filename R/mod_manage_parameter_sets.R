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
      actionButton(ns("add_parameter"), "Add parameter", icon = icon("plus")),
      actionButton(ns("edit_parameters"), "Edit parameter sets", icon = icon("edit"))
    ),
    br()
  )
}

#' manage_parameter_sets Server Functions
#'
#' @noRd
mod_manage_parameter_sets_server <- function(id, r, tab_section){
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
        removeModal()
      }
    })

    # Activate/Deactivate Edit Parameters mode
    observeEvent(input$edit_parameters, {
      r$states$edit_mode_parameters_set <- (!r$states$edit_mode_parameters_set)
      updateActionButton(session, "edit_parameters",
                         label = if (r$states$edit_mode_parameters_set) "Finish editing" else "Edit parameters")

    })

    # Handle all tabs removed
    observeEvent(r$data[[tab_section]]$sheets, {
      if(length(r$data[[tab_section]]$sheets) == 0){
        r$states$edit_mode_parameters_set <- FALSE
        updateActionButton(session, "edit_parameters", label = "Edit parameters")
      }
    })

  })
}

## To be copied in the UI
# mod_manage_parameter_sets_ui("manage_parameter_sets_1")

## To be copied in the server
# mod_manage_parameter_sets_server("manage_parameter_sets_1")
