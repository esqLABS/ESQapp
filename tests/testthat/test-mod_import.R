test_that("Columns are correctly typed", {

  file <- "Scenarios.xslx"
  sheet <- "Scenarios"

  scenarios_original <- rio::import(file = test_path("data", "Parameters", "Scenarios.xlsx"),
                                    sheet = sheet,
                                    col_types = "text",
                                    setclass = "tibble")

  scenarios_modified <-  type_columns(scenarios_original,
                                      config_file = tolower(fs::path_ext_remove(file)),
                                      sheet = sheet)

  expect_snapshot(scenarios_modified)

})
