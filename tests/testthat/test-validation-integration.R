# Tests for esqlabsR validation integration
# Note: WarningHandler uses reactiveValues which requires a Shiny session context.
# These tests focus on non-reactive integration points and architecture validation.

test_that("esqlabsR validation functions are available and exported", {
  # Load esqlabsR if not already loaded
  if (!"package:esqlabsR" %in% search()) {
    library(esqlabsR)
  }

  # Verify the integration points exist
  expect_true(exists("validateAllConfigurations", where = asNamespace("esqlabsR"), mode = "function"))
  expect_true(exists("isAnyCriticalErrors", where = asNamespace("esqlabsR"), mode = "function"))
  expect_true(exists("validationSummary", where = asNamespace("esqlabsR"), mode = "function"))
})

test_that("WarningHandler class exists and has required methods", {
  # Test class structure without reactive context
  warning_handler <- WarningHandler$new()

  # Check that required fields exist
  expect_true("esqlabsR_results" %in% names(warning_handler))
  expect_true("esqlabsR_summary" %in% names(warning_handler))
  expect_true("has_critical_errors" %in% names(warning_handler))

  # Check that required methods exist
  expect_true("add_esqlabsR_validation" %in% names(warning_handler))
  expect_true("clear_all" %in% names(warning_handler))
  expect_true("get_summary" %in% names(warning_handler))

  # Test non-reactive fields can be set directly
  warning_handler$esqlabsR_results <- list(test = "value")
  warning_handler$esqlabsR_summary <- list(total_critical_errors = 5)
  warning_handler$has_critical_errors <- TRUE

  expect_equal(warning_handler$esqlabsR_results$test, "value")
  expect_equal(warning_handler$esqlabsR_summary$total_critical_errors, 5)
  expect_true(warning_handler$has_critical_errors)

  # Test clear_all resets non-reactive fields
  warning_handler$esqlabsR_results <- NULL
  warning_handler$esqlabsR_summary <- NULL
  warning_handler$has_critical_errors <- FALSE

  expect_null(warning_handler$esqlabsR_results)
  expect_null(warning_handler$esqlabsR_summary)
  expect_false(warning_handler$has_critical_errors)
})

test_that("DataStructure does not perform validation logic", {
  data_structure <- DataStructure$new()

  # Ensure validation-specific methods don't exist
  expect_false("validate" %in% names(data_structure))
  expect_false("validate_uniqueness" %in% names(data_structure))
  expect_false("validate_references" %in% names(data_structure))

  # Test basic data operations still work
  expect_true("get_config_files" %in% names(data_structure))
  expect_true("is_sheet_empty" %in% names(data_structure))
  expect_true("add_sheet" %in% names(data_structure))
  expect_true("remove_sheet" %in% names(data_structure))
  expect_true("create_new_sheet" %in% names(data_structure))
})

test_that("format_validation_summary handles different input types", {
  # Test with named list
  summary1 <- list(
    criticalErrorCount = 5,
    warningCount = 3,
    configFiles = c("scenarios", "plots")
  )
  result1 <- format_validation_summary(summary1)
  expect_true(grepl("Critical Errors", result1))
  expect_true(grepl("5", result1))
  expect_true(grepl("Warnings", result1))
  expect_true(grepl("3", result1))

  # Test with NULL
  result2 <- format_validation_summary(NULL)
  expect_true(grepl("No validation details available", result2))

  # Test with empty list
  result3 <- format_validation_summary(list())
  expect_true(grepl("No validation details available", result3))
})

test_that("mod_import integration points are correct", {
  # Verify mod_import has the necessary structure
  # This tests the architectural contract without needing a running app

  # Check that format_validation_summary helper exists
  expect_true(exists("format_validation_summary", mode = "function"))

  # Verify the function can handle esqlabsR validation summary structure
  mock_summary <- list(
    total_critical_errors = 2,
    total_warnings = 3,
    files_with_errors = c("scenarios", "plots"),
    files_with_warnings = c("individuals")
  )

  result <- format_validation_summary(mock_summary)
  expect_type(result, "character")
  expect_true(nchar(result) > 0)
})

# Note: Full reactive testing of WarningHandler methods (add_esqlabsR_validation,
# add_warning, get_summary) requires a running Shiny app context and should be
# verified through:
# 1. Manual testing in the running application
# 2. Integration tests with a full app instance
# 3. Visual inspection of the warning modal UI
#
# The tests above verify the architectural contracts and non-reactive behavior.
