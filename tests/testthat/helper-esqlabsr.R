#' Initialize or refresh the latest esqlabsR test project
#'
#' This helper function removes the existing test project data directory
#' (default: `tests/testthat/data/`) and re-initializes it with the latest version
#' using [esqlabsR::initProject()].
#'
#' @param data_dir Character path to the test project directory.
#'   Defaults to `"tests/testthat/data/"`.
#'
#' @return
#' Invisibly returns the result of [esqlabsR::initProject()].
#'
#' @keywords internal
refresh_esqlabsR_test_project <- function(data_dir = "tests/testthat/data/") {
  # Ensure the directory exists
  if (!dir.exists(data_dir)) {
    dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  } else {
    # Remove everything inside, but keep the directory itself
    entries <- list.files(
      data_dir,
      all.files  = TRUE,
      full.names = TRUE,
      no..       = TRUE
    )
    if (length(entries)) {
      unlink(entries, recursive = TRUE, force = TRUE)
    }
  }

  # Re-initialize with the latest scaffold
  esqlabsR::initProject(destination = data_dir, overwrite = TRUE)
}
