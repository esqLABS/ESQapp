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
          title = "Validation Results",
          uiOutput(ns("warning_accordion")),
          easyClose = TRUE,
          footer = tagList(
            actionButton(ns("close_warning_modal"), "Close")
          )
        )
      )
    })

    # Watch for critical errors
    observeEvent(r$warnings$critical_messages$config_files, {
      updateActionButton(
        session = session,
        inputId = "open_warning_modal",
        icon = icon("circle-exclamation"),
        disabled = FALSE
      )

      showNotification(
        HTML(paste(
          "Critical errors found in config files. Press the",
          icon("circle-exclamation"), "to view them"
        )),
        type = "error",
        duration = 10
      )

      .render_accordion(output, ns, r)
    })

    # Watch for warnings (only update icon if no critical errors)
    observeEvent(r$warnings$warning_messages$config_files, {
      if (!r$warnings$has_critical_errors()) {
        updateActionButton(
          session = session,
          inputId = "open_warning_modal",
          icon = icon("triangle-exclamation"),
          disabled = FALSE
        )

        showNotification(
          HTML(paste(
            "Warnings found in config files. Press the",
            icon("triangle-exclamation"), "to view them"
          )),
          type = "warning",
          duration = 7
        )
      }

      .render_accordion(output, ns, r)
    })

    observeEvent(input$close_warning_modal, {
      removeModal()
    })
  })
}

#' Render the warning/error accordion into an output
#' @noRd
.render_accordion <- function(output, ns, r) {
  output$warning_accordion <- renderUI({
    # Collect all config files that have issues
    all_files <- unique(c(
      r$warnings$critical_messages$config_files,
      r$warnings$warning_messages$config_files
    ))

    items <- lapply(all_files, function(x) {
      content_parts <- list()

      # Critical errors section
      critical_msgs <- r$warnings$critical_messages[[x]]
      if (length(critical_msgs) > 0) {
        bullets <- paste0("<li>", critical_msgs, "</li>", collapse = "")
        content_parts <- c(content_parts, list(HTML(paste0(
          "<div style='color: #dc3545; margin-bottom: 8px;'>",
          "<strong>Critical Errors:</strong>",
          "<ul>", bullets, "</ul></div>"
        ))))
      }

      # Warnings section
      warning_msgs <- r$warnings$warning_messages[[x]]
      if (length(warning_msgs) > 0) {
        bullets <- paste0("<li>", warning_msgs, "</li>", collapse = "")
        content_parts <- c(content_parts, list(HTML(paste0(
          "<div style='color: #856404;'>",
          "<strong>Warnings:</strong>",
          "<ul>", bullets, "</ul></div>"
        ))))
      }

      if (length(content_parts) == 0) {
        content_parts <- list("No issues.")
      }

      accordion_panel(paste("File:", x), tagList(content_parts))
    })

    accordion(!!!items, multiple = FALSE)
  })
}
