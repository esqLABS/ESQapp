#' Create a cross button for removing a parameter in a Shiny app
#'
#' @param sheet The name of the sheet associated with the button
#' @param ns A namespace function for generating unique input IDs
#'
#' @return
#' A Shiny action button with styling and an onclick event to update the input value.
cross_btn <- function(sheet, ns) {
  tagList(
    actionButton(
      inputId = ns(paste("remove", sheet, sep = "_")),
      label = "x",
      class = "btn-close",
      onclick = sprintf(
        "Shiny.setInputValue('%s', '%s');",
        ns("remove_parameter_name"),
        sheet
      ),
      style = "
               margin-left: 10px;
               padding: 0;
               font-size: 14px;
               background: none;
               border: none;
               cursor: pointer;
               position: absolute;
               right: -23px;
               top: -18px;
               color: red;
              "
    )
  )
}

#' Create Save Project Dropdown Button
#'
#' @description Creates a Bootstrap dropdown button with options to save project
#' as .esqapp or .zip format. Used in both export module and import confirmation modal.
#'
#' @param ns Namespace function from the Shiny module
#' @param esqapp_id ID for the .esqapp download button
#' @param zip_id ID for the .zip download button
#' @param button_id ID for the main dropdown button (default: "downloadButton")
#' @param button_label Label for the main dropdown button (default: " Save Project ")
#' @param button_class CSS class for the button (default: "btn btn-dark dropdown-toggle")
#' @param button_style Additional inline styles for the button
#' @param button_icon Icon for the button (default: download icon)
#' @param disabled Whether the button should be initially disabled (default: FALSE)
#'
#' @return A tagList containing the dropdown button UI
#'
#' @noRd
save_dropdown_ui <- function(ns,
                             esqapp_id,
                             zip_id,
                             button_id = "downloadButton",
                             button_label = " Save Project ",
                             button_class = "btn btn-dark dropdown-toggle",
                             button_style = "width: 100%; padding: 10px 10px;",
                             button_icon = shiny::icon("download"),
                             disabled = FALSE) {
  # Build button with conditional disabled attribute
  btn_args <- list(
    id = ns(button_id),
    type = "button",
    class = button_class,
    style = button_style,
    `data-bs-toggle` = "dropdown",
    `aria-expanded` = "false",
    button_icon,
    button_label,
    shiny::tags$span(class = "caret")
  )
  if (disabled) {
    btn_args$disabled <- NA
  }

  shiny::tags$div(
    class = "btn-group",
    style = "width: 100%;",
    role = "group",
    do.call(shiny::tags$button, btn_args),
    shiny::tags$ul(
      class = "dropdown-menu",
      style = "width: 100%;",
      shiny::tags$li(
        shiny::downloadButton(
          ns(esqapp_id),
          label = shiny::tagList(
            shiny::icon("file-archive"),
            " Save as ",
            shiny::tags$em(style = "color: #404040; font-weight: 100;", ".esqapp")
          ),
          class = "btn-link",
          style = "width: 100%; text-align: left; border: none; padding: 8px 10px;"
        )
      ),
      shiny::tags$li(shiny::tags$hr(class = "dropdown-divider", style = "margin: 5px 0;")),
      shiny::tags$li(
        shiny::downloadButton(
          ns(zip_id),
          label = shiny::tagList(
            shiny::icon("file-zipper"),
            " Save as ",
            shiny::tags$em(style = "color: #404040; font-weight: 100;", ".zip")
          ),
          class = "btn-link",
          style = "width: 100%; text-align: left; border: none; padding: 8px 10px;"
        )
      )
    )
  )
}
