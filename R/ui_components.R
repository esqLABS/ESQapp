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
