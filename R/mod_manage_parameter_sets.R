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

    showDeleteConfirmationModal <- reactiveVal(FALSE)

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

    # Activate Confirmation modal window
    observeEvent(input$remove_parameters, {
      showDeleteConfirmationModal(TRUE)
    })

    # Show confirmation modal for deletion
    observeEvent(showDeleteConfirmationModal(), {
      if(showDeleteConfirmationModal()){
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
      } else {
        removeModal()
        showDeleteConfirmationModal(FALSE)
      }
    })

    # Handle deletion confirmation
    observeEvent(input$confirm_delete, {
      # Send current tab_section name to the parent module and trigger deletion observeEvent there
      r$states[[state_name]] <- list(tab_section = tab_section)
      # Update global `DROPDOWN` options (sourced from sheet names)
      DROPDOWNS$applications$application_protocols <- r$data$applications$sheets |> unique()
      DROPDOWNS$scenarios$model_parameters <- r$data$models$sheets |> unique()
      # Remove modal window
      removeModal()
      showDeleteConfirmationModal(FALSE)
    })


    # Handle all tabs removed
    observeEvent(r$data[[tab_section]]$sheets, {
      if(length(r$data[[tab_section]]$sheets) == 0){
        r$states[[state_name]] <- NULL # Send nothing to the observeEvent in the parent module
      }
    })

  })
}

## To be copied in the UI
# mod_manage_parameter_sets_ui("manage_parameter_sets_1")

## To be copied in the server
# mod_manage_parameter_sets_server("manage_parameter_sets_1")
