get_projectConfiguration <- function() {
  path <- testthat::test_path("data", "ProjectConfiguration.xlsx")
  stopifnot(file.exists(path))

  got_warning <- NULL
  cfg <- withCallingHandlers(
    esqlabsR::createProjectConfiguration(path),
    warning = function(w) {
      if (is.null(got_warning)) got_warning <<- conditionMessage(w)
      invokeRestart("muffleWarning")
    }
  )

  attr(cfg, "warning") <- got_warning
  attr(cfg, "path")    <- path
  cfg
}
