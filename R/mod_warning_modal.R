#' warning modal UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_warning_ui <- function(id) {
  ns <- NS(id)
    # Show warning icon
    bslib::nav_item(
      actionButton(
        inputId = ns("open_warning_modal"),
        label = NULL,
        icon = icon("bell"),
        disabled = TRUE,
        style = "color: black;"
      )
    )
}

#' warning Server Functions
#'
#' @noRd
mod_warning_server <- function(id, r) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observeEvent(input$open_warning_modal, {
      showModal(
        modalDialog(
          title = "Warning",
          uiOutput(ns("warning_accordion")),
          easyClose = TRUE,
          footer = tagList(
            actionButton(ns("close_warning_modal"), "Close")
          )
        )
      )
    })

    observeEvent(r$warnings$warning_messages$config_files, {
      updateActionButton(
        session = session,
        inputId = "open_warning_modal",
        icon = icon("warning"),
        disabled = FALSE
      )

      showNotification(
        HTML(paste("Warnings found in config files. Press the", icon("warning"), "to view them")),
        type = "warning",
        duration = 7
      )

      output$warning_accordion <- renderUI({
        items <- lapply(unique(r$warnings$warning_messages$config_files), function(x) {
          # Check if there are messages for the current config file
          if (length(r$warnings$warning_messages[[x]]) > 0) {
            # Loop through each message inside the vector and create a list item
            bullet_list <- sapply(r$warnings$warning_messages[[x]], function(msg) {
              paste0("<li>", msg, "</li>")
            })
            # Combine the bullet list items into a single string
            bullet_list_content <- paste(bullet_list, collapse = "")
            # Wrap the content in an unordered list <ul> and pass to the accordion panel
            accordion_panel(paste("File: ", x), HTML(paste("<ul>", bullet_list_content, "</ul>")))
          } else {
            # In case there are no messages, just show a message in the accordion panel
            accordion_panel(paste("File: ", x), "No warnings.")
          }
        })

        # Return the accordion with the items
        accordion(!!!items, multiple = FALSE)

      })
    })

    observeEvent(input$close_warning_modal, {
      removeModal()
    })


  })
}
