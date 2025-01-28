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
    tags$head(
      golem::bundle_resources(
        path = app_sys("app/www"),
        app_title = "Your App Title"
      ),
      # Add your JS script here
      tags$script(src = "www/app_exit_protection.js")
    ),
    # Your application UI logic
    bslib::page_navbar(
      title = span(
        img(
          src = "www/ESQLabs_Sign_RZ_positive_Rings - Copy.png",
          width = 55,
          style = "font-weight: bold;"
        ),
        span(style="font-weight: 600;", "ESQapp")
      ),
      sidebar = mod_sidebar_ui("sidebar_1"),
      nav_spacer(),
      !!!mod_main_panel_ui("main_panel_1"),
      # Show warning modal
      mod_warning_ui("warning_modal")

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
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "ESQapp"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
