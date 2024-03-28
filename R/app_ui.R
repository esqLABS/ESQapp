#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @import bslib
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    esqlabs.ui::intro_screen(width = '100%'),
    # Your application UI logic
    bslib::page_navbar(
      title = "shinyScenarioEditor",
      sidebar = mod_sidebar_ui("sidebar_1"),
      !!!mod_main_panel_ui("main_panel_1")
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    # tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "shinyScenarioEditor"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
