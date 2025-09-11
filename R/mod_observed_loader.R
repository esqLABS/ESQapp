#' observed_loader UI Function
#'
#' @noRd
mod_observed_loader_ui <- function(id) {
  ns <- NS(id)
  tagList(
    actionButton(ns("open_loader"), "Load observed data")
  )
}

#' observed_loader Server Function
#'
#' @noRd
mod_observed_loader_server <- function(id, r, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observeEvent(input$open_loader, {
      # Validation: chech config path presence
      if (is.null(r$config) || is.null(r$config$projectConfiguration)) {
        showModal(modalDialog("Project configuration is not loaded yet.", easyClose = TRUE))
        return(invisible(NULL))
      }

      # Pull current state
      available <- isolate(r$observed_store$available %||% character(0))
      loaded    <- isolate(r$observed_store$loaded    %||% character(0))

      # Show modal if no sheets available for the project
      if (length(available) == 0) {
        showModal(modalDialog("No observed sheets available to load.", easyClose = TRUE))
        return(invisible(NULL))
      }

      # show sheets that aren't loaded yet
      selectable <- setdiff(available, loaded)

      # Show modal if all sheets already loaded
      if (length(selectable) == 0) {
        showModal(modalDialog(
          title = "Load observed data",
          tagList(
            p("All detected observed sheets are already loaded."),
            if (length(loaded) > 0) {
              tags$small(
                HTML(paste0("<b>Loaded:</b> ",
                            paste(vapply(loaded, htmltools::htmlEscape, ""), collapse = ", ")))
              )
            }
          ),
          easyClose = TRUE
        ))
        return(invisible(NULL))
      }

      # Main modal to load data
      showModal(
        modalDialog(
          title = "Load observed data",
          tagList(
            if (length(loaded) > 0) {
              tags$small(
                HTML(paste0("<b>Loaded:</b> ",
                            paste(vapply(loaded, htmltools::htmlEscape, ""), collapse = ", ")))
              )
            },
            br(),
            br(),
            p("Select the sheets to load:"),
            div(style = "display: flex; gap: 0.5rem; margin-bottom: 1rem",
                actionButton(session$ns("select_all"), class ="btn-outline-primary btn-sm", "Select all", icon = icon("check")),
                actionButton(session$ns("clear_all"), class ="btn-sm",  "Deselect all")
            ),
            checkboxGroupInput(
              inputId = session$ns("selectedSheets"),
              label = NULL,
              choices = selectable,
              selected = NULL
            ),
            br()
          ),
          footer = tagList(
            actionButton(session$ns("cancel_load_data"), class ="btn-light", "Cancel"),
            actionButton(session$ns("confirm_load_data"), class ="btn-outline-success", "Load selected", disabled = TRUE)
          ),
          easyClose = FALSE,
          size = "m"
        )
      )


      # Disable/Enable load data button
      observeEvent(input$selectedSheets, {
        sel <- input$selectedSheets %||% character(0)
        if (length(sel) > 0) {
          updateActionButton(session, 'confirm_load_data', disabled = FALSE)
        } else {
          updateActionButton(session, 'confirm_load_data', disabled = TRUE)
        }
      }, ignoreNULL = FALSE)

      # Close button
      observeEvent(input$cancel_load_data, ignoreInit = TRUE, once = TRUE, {
        removeModal()
      })

      # Confirm button
      observeEvent(input$confirm_load_data, ignoreInit = TRUE, once = TRUE, {
        removeModal()
        sel <- input$selectedSheets %||% character(0)
        if (length(sel) > 0) {
          observed_data <- tryCatch(
            esqlabsR::loadObservedData(isolate(r$config$projectConfiguration), sel),
            error = function(e) {
              r$states$modal_message <- list(
                status  = "Error loading observed data",
                message = paste("Details:", conditionMessage(e))
              )
              NULL
            }
          )

          if (!is.null(observed_data)) {
            r$observed_store$observed_data[names(observed_data)] <- observed_data
            DROPDOWNS$plots$datasets_options <- unique(names(r$observed_store$observed_data))
            # Mark selected sheets as loaded
            r$observed_store$loaded <- union(isolate(r$observed_store$loaded), sel)
          }

        }
      })

      # Select all
      observeEvent(input$select_all, {
        updateCheckboxGroupInput(session, "selectedSheets", selected = selectable)
      })
      # Deselect all
      observeEvent(input$clear_all, {
        updateCheckboxGroupInput(session, "selectedSheets", selected = character(0))
      })


    })
  })
}
