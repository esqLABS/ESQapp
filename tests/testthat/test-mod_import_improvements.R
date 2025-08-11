# Test for the improved file selection dialog
# This file tests the new functionality in mod_import.R

test_that("mod_import_ui creates modern file input interface", {
  # Test the UI function
  ui_output <- mod_import_ui("test")
  
  # Should contain a bslib::card
  expect_true(any(grepl("card", as.character(ui_output))))
  
  # Should contain fileInput instead of shinyFilesButton
  expect_true(any(grepl("fileInput", as.character(ui_output))))
  
  # Should not contain shinyFilesButton
  expect_false(any(grepl("shinyFilesButton", as.character(ui_output))))
  
  # Should contain drag and drop text
  expect_true(any(grepl("Drag and drop", as.character(ui_output))))
  
  # Should contain Excel file acceptance
  expect_true(any(grepl("\\.xlsx", as.character(ui_output))))
})

test_that("file input accepts correct file types", {
  # Test that the fileInput accepts .xlsx and .xls files
  ui_output <- mod_import_ui("test")
  ui_string <- as.character(ui_output)
  
  # Should accept both xlsx and xls
  expect_true(any(grepl("accept.*xlsx", ui_string)))
  expect_true(any(grepl("accept.*xls", ui_string)))
})

test_that("modern styling is applied", {
  # Test that modern styling classes and attributes are present
  ui_output <- mod_import_ui("test")
  ui_string <- as.character(ui_output)
  
  # Should have blue dashed border styling
  expect_true(any(grepl("border.*dashed.*007bff", ui_string)))
  
  # Should have center text alignment
  expect_true(any(grepl("text-center", ui_string)))
  
  # Should contain file icon emoji
  expect_true(any(grepl("📁", ui_string)))
})

# Note: Server function tests would require setting up a Shiny test environment
# These would test:
# - File validation logic
# - Error notifications for invalid files
# - Proper file info extraction
# - Integration with esqlabsR::createDefaultProjectConfiguration