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

    # Show Dialog to Add parameter set
    observeEvent(input$add_parameter, {
      showModal(
        modalDialog(
          title = "Add Parameter Set",
          textInput(ns("parameter_name"), "Parameter Name"),
          footer = tagList(
            actionButton(ns("add_parameter_button"), "Add Parameter Set"),
            modalButton("Cancel")
          )
        )
      )
    })

    # Add Parameter Set
    observeEvent(input$add_parameter_button, {
      # Replace " with ' inside parameter_name before using it
      clean_parameter_name <- gsub('"', "'", input$parameter_name)
      if(clean_parameter_name %in% r$data[[tab_section]]$sheets){
        showModal(
          modalDialog(
            title = "Error",
            "Parameter already exists. Try another name.",
            footer = modalButton("OK")
          )
        )
      } else {
        r$data$create_new_sheet(tab_section, clean_parameter_name)
        # Update global `DROPDOWN` options (sourced from sheet names)
        DROPDOWNS$applications$application_protocols <- r$data$applications$sheets |> unique()
        DROPDOWNS$scenarios$model_parameters <- r$data$models$sheets |> unique()
        removeModal()
      }
    })

    # Show confirmation modal for deletion - directly show modal on button click
    observeEvent(input$remove_parameters, {
      showModal(
        modalDialog(
          title = "Delete Parameter Set",
          "Are you sure you want to delete current parameter set?",
          footer = tagList(
            actionButton(ns("confirm_delete"), "Delete", class = "btn btn-danger"),
            modalButton("Cancel")
          )
        )
      )
    })

    # Handle deletion confirmation
    observeEvent(input$confirm_delete, {
      # Send current tab_section name to the parent module and trigger deletion observeEvent there
      # Include timestamp to ensure observeEvent always triggers (even if tab_section is same)
      r$states[[state_name]] <- list(tab_section = tab_section, timestamp = Sys.time())
      # Note: DROPDOWNS are updated in mod_table_tab.R AFTER the sheet is actually deleted
      # Remove modal window
      removeModal()
    })


    # Handle all tabs removed - also update DROPDOWNS when sheets become empty
    observeEvent(r$data[[tab_section]]$sheets, {
      if(length(r$data[[tab_section]]$sheets) == 0){
        # Update DROPDOWNS to reflect empty sheets list
        DROPDOWNS$applications$application_protocols <- r$data$applications$sheets |> unique()
        DROPDOWNS$scenarios$model_parameters <- r$data$models$sheets |> unique()
        r$states[[state_name]] <- NULL # Send nothing to the observeEvent in the parent module
      }
    })

  })
}

## To be copied in the UI
# mod_manage_parameter_sets_ui("manage_parameter_sets_1")

## To be copied in the server
# mod_manage_parameter_sets_server("manage_parameter_sets_1")
