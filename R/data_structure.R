data_structure <- function() {
  list(
    "scenarios" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "individuals" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "populations" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "models" = reactiveValues(
      file_path = NA,
      sheets = NA
    ),
    "plots" = reactiveValues(
      file_path = NA,
      sheets = NA
    )
  )
}
