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
      # Determine title based on presence of critical errors
      modal_title <- if (r$warnings$has_critical_errors) {
        "Validation Results - Critical Errors & Warnings"
      } else {
        "Validation Results - Warnings"
      }

      showModal(
        modalDialog(
          title = modal_title,
          size = "l",
          uiOutput(ns("validation_tabs")),
          easyClose = TRUE,
          footer = tagList(
            actionButton(ns("close_warning_modal"), "Close")
          )
        )
      )
    })

    # Update button icon and notification based on validation results
    observeEvent(list(r$warnings$warning_messages$config_files, r$warnings$critical_errors), {
      # Determine icon based on presence of critical errors
      if (r$warnings$has_critical_errors) {
        updateActionButton(
          session = session,
          inputId = "open_warning_modal",
          icon = icon("exclamation-triangle"),
          disabled = FALSE
        )
        showNotification(
          HTML(paste("Critical errors found in config files. Press the", icon("exclamation-triangle"), "to view them")),
          type = "error",
          duration = 10
        )
      } else if (length(r$warnings$warning_messages$config_files) > 0) {
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
      }

      # Render the validation results as tabs
      output$validation_tabs <- renderUI({
        tabs_list <- list()

        # Critical Errors Tab (if any exist)
        if (r$warnings$has_critical_errors) {
          critical_items <- lapply(names(r$warnings$critical_errors), function(config_file) {
            if (length(r$warnings$critical_errors[[config_file]]) > 0) {
              bullet_list <- sapply(r$warnings$critical_errors[[config_file]], function(msg) {
                paste0("<li class='text-danger'>", msg, "</li>")
              })
              bullet_list_content <- paste(bullet_list, collapse = "")
              accordion_panel(
                paste("File:", config_file),
                HTML(paste("<ul>", bullet_list_content, "</ul>"))
              )
            }
          })

          critical_content <- accordion(!!!critical_items[!sapply(critical_items, is.null)], multiple = TRUE)

          tabs_list$critical <- tabPanel(
            title = span(icon("exclamation-circle"), "Critical Errors", style = "color: #dc3545;"),
            br(),
            h5("These errors must be fixed before data can be imported:"),
            hr(),
            critical_content
          )
        }

        # Warnings Tab (if any exist)
        if (length(r$warnings$warning_messages$config_files) > 0) {
          warning_items <- lapply(unique(r$warnings$warning_messages$config_files), function(x) {
            if (length(r$warnings$warning_messages[[x]]) > 0) {
              bullet_list <- sapply(r$warnings$warning_messages[[x]], function(msg) {
                paste0("<li class='text-warning'>", msg, "</li>")
              })
              bullet_list_content <- paste(bullet_list, collapse = "")
              accordion_panel(
                paste("File:", x),
                HTML(paste("<ul>", bullet_list_content, "</ul>"))
              )
            }
          })

          warning_content <- accordion(!!!warning_items[!sapply(warning_items, is.null)], multiple = TRUE)

          tabs_list$warnings <- tabPanel(
            title = span(icon("exclamation-triangle"), "Warnings", style = "color: #ffc107;"),
            br(),
            h5("These issues should be reviewed but don't block import:"),
            hr(),
            warning_content
          )
        }

        # Summary Tab
        summary <- r$warnings$get_summary()
        summary_content <- HTML(paste0(
          "<div class='validation-summary'>",
          "<h5>Validation Summary</h5>",
          "<table class='table table-bordered'>",
          "<tr><td><strong>Total Critical Errors:</strong></td><td>",
          ifelse(summary$total_critical_errors > 0,
                 paste0("<span class='text-danger'>", summary$total_critical_errors, "</span>"),
                 "<span class='text-success'>0</span>"),
          "</td></tr>",
          "<tr><td><strong>Total Warnings:</strong></td><td>",
          ifelse(summary$total_warnings > 0,
                 paste0("<span class='text-warning'>", summary$total_warnings, "</span>"),
                 "<span class='text-success'>0</span>"),
          "</td></tr>",
          "<tr><td><strong>Files Validated:</strong></td><td>",
          paste(summary$affected_files, collapse = ", "),
          "</td></tr>",
          "<tr><td><strong>Status:</strong></td><td>",
          ifelse(summary$has_critical_errors,
                 "<span class='text-danger'><strong>❌ Cannot Proceed - Fix Critical Errors</strong></span>",
                 "<span class='text-success'><strong>✅ Can Proceed - Review Warnings</strong></span>"),
          "</td></tr>",
          "</table>",
          "</div>"
        ))

        tabs_list$summary <- tabPanel(
          title = span(icon("info-circle"), "Summary"),
          br(),
          summary_content
        )

        # Return tabsetPanel with all tabs
        do.call(tabsetPanel, c(tabs_list, list(id = ns("validation_tabs_panel"))))
      })
    })

    observeEvent(input$close_warning_modal, {
      removeModal()
    })
  })
}
