test_that("ProjectConfigurationJSON loads valid JSON file without errors", {
  json_path <- testthat::test_path("data", "ProjectConfiguration.json")
  skip_if_not(file.exists(json_path), "Test JSON file not found")

  config <- ProjectConfigurationJSON$new(json_path)

  expect_false(config$has_errors())
  expect_s3_class(config, "ProjectConfigurationJSON")
  expect_equal(config$file_path, normalizePath(json_path, winslash = "/"))
})

test_that("ProjectConfigurationJSON reports errors for invalid files", {
  config <- ProjectConfigurationJSON$new("nonexistent_file.json")
  expect_true(config$has_errors())
  expect_equal(config$errors$items[[1]]$code, "E001")

  temp_file <- tempfile(fileext = ".xlsx")
  file.create(temp_file)
  on.exit(unlink(temp_file))

  config2 <- ProjectConfigurationJSON$new(temp_file)
  expect_true(config2$has_errors())
  expect_true("E002" %in% sapply(config2$errors$items, `[[`, "code"))
})

test_that("ProjectConfigurationJSON parses all sections correctly", {
  json_path <- testthat::test_path("data", "ProjectConfiguration.json")
  skip_if_not(file.exists(json_path), "Test JSON file not found")

  config <- ProjectConfigurationJSON$new(json_path)

  expect_equal(config$project_settings$modelFolder, "Models/Simulations/")

  expect_equal(length(config$scenarios), 2)
  expect_equal(length(config$individuals), 2)

  expect_equal(length(config$populations), 2)
  expect_equal(length(config$model_parameters), 3)
  expect_equal(length(config$applications), 1)
  expect_equal(length(config$plots), 7)

  expect_equal(nrow(config$scenarios$Scenarios), 5)
  expect_equal(nrow(config$individuals$IndividualBiometrics), 1)
  expect_equal(nrow(config$populations$Demographics), 2)
  expect_equal(nrow(config$plots$DataCombined), 4)
})

test_that("ProjectConfigurationJSON handles edge cases in JSON structure", {
  json_path <- testthat::test_path("data", "ProjectConfiguration.json")
  skip_if_not(file.exists(json_path), "Test JSON file not found")

  config <- ProjectConfigurationJSON$new(json_path)

  expect_equal(ncol(config$plots$dataTypes), 1)
  expect_equal(nrow(config$plots$dataTypes), 2)
  expect_equal(names(config$plots$dataTypes), "dataType")

  expect_equal(ncol(config$plots$plotTypes), 1)
  expect_equal(nrow(config$plots$plotTypes), 5)

  expect_equal(nrow(config$plots$exportConfiguration), 0)
  expect_true(ncol(config$plots$exportConfiguration) > 0)

  expect_equal(nrow(config$populations$UserDefinedVariability), 0)
  expect_true(ncol(config$populations$UserDefinedVariability) > 0)

  expect_s3_class(config$plots$ObservedDataNames, "data.frame")
  expect_equal(nrow(config$plots$ObservedDataNames), 0)
})

test_that("ProjectConfigurationJSON get_sheet_names and get_sheet_data work", {
  json_path <- testthat::test_path("data", "ProjectConfiguration.json")
  skip_if_not(file.exists(json_path), "Test JSON file not found")

  config <- ProjectConfigurationJSON$new(json_path)

  expect_true("Scenarios" %in% config$get_sheet_names("scenarios"))
  expect_true("Global" %in% config$get_sheet_names("models"))

  scenarios_df <- config$get_sheet_data("scenarios", "Scenarios")
  expect_s3_class(scenarios_df, "data.frame")
  expect_true(nrow(scenarios_df) > 0)

  expect_null(config$get_sheet_data("scenarios", "NonExistent"))
})

test_that("ProjectConfigurationJSON export and reimport preserves data", {
  json_path <- testthat::test_path("data", "ProjectConfiguration.json")
  skip_if_not(file.exists(json_path), "Test JSON file not found")

  config <- ProjectConfigurationJSON$new(json_path)

  temp_json <- tempfile(fileext = ".json")
  on.exit(unlink(temp_json))

  expect_true(config$export(temp_json))

  config2 <- ProjectConfigurationJSON$new(temp_json)
  expect_false(config2$has_errors())

  expect_equal(config$project_settings$modelFolder, config2$project_settings$modelFolder)
  expect_equal(nrow(config$scenarios$Scenarios), nrow(config2$scenarios$Scenarios))
  expect_equal(names(config$plots), names(config2$plots))
})

test_that("ValidationErrorCollection and ValidationWarningCollection work", {
  errors <- ValidationErrorCollection$new()
  expect_equal(errors$count(), 0)

  errors$add("E001", "file", "Test error")
  expect_equal(errors$count(), 1)
  expect_true(errors$has_errors())

  errors$clear()
  expect_equal(errors$count(), 0)

  warnings <- ValidationWarningCollection$new()
  warnings$add("W001", "file", "Test warning")
  expect_equal(warnings$count(), 1)
  expect_true(warnings$has_warnings())
})
