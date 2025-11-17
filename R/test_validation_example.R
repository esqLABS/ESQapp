#' Test Script for Three-Tier Validation System
#'
#' This script demonstrates how to use the new validation system
#' with esqlabsR validations integrated into ESQapp

# Load required libraries
library(shiny)
library(R6)
library(readxl)

# Source the validation files
source("validation_result.R")
source("validation_utils.R")

# Example 1: Test ValidationResult Class
cat("=================================================\n")
cat("Example 1: Creating and Using ValidationResult\n")
cat("=================================================\n\n")

# Create a new validation result
result <- ValidationResult$new("test_file.xlsx", "test_validation")

# Add some critical errors
result$add_critical_error(
  "Missing Fields",
  "DataCombinedName is missing in row 3",
  "Sheet: DataCombined"
)

result$add_critical_error(
  "Uniqueness Violation",
  "Duplicate plotIDs found: plot1, plot2",
  "Sheet: plotConfiguration"
)

# Add some warnings
result$add_warning(
  "Invalid Reference",
  "Scenario 'TestScenario' does not exist",
  "Sheet: DataCombined, Row 5",
  "Verify scenario name or add it to scenarios file"
)

result$add_warning(
  "Missing Fields",
  "Output filename missing, will use default",
  "Sheet: exportConfiguration",
  "Specify outputFileName for custom export names"
)

# Print the result
print(result)

cat("\n\nFormatted Messages:\n")
cat("Critical Errors:\n")
for (msg in result$get_formatted_messages("critical")) {
  cat("  - ", msg, "\n")
}

cat("\nWarnings:\n")
for (msg in result$get_formatted_messages("warning")) {
  cat("  - ", msg, "\n")
}

# Example 2: Validate a Project Configuration
cat("\n\n=================================================\n")
cat("Example 2: Validating Project Configuration\n")
cat("=================================================\n\n")

# This would validate an actual project configuration file
# Uncomment the following lines if you have a test file:
#
# pc_path <- "path/to/your/projectConfiguration.xlsx"
# if (file.exists(pc_path)) {
#   pc_validation <- validate_project_configuration(pc_path)
#   print(pc_validation)
#
#   if (pc_validation$is_valid()) {
#     cat("✅ Project configuration is valid!\n")
#     cat("Data available: ", !is.null(pc_validation$data), "\n")
#   } else {
#     cat("❌ Project configuration has critical errors!\n")
#   }
# }

# Example 3: Demonstrate the Three-Tier System Flow
cat("\n\n=================================================\n")
cat("Example 3: Three-Tier Validation Flow\n")
cat("=================================================\n\n")

simulate_validation <- function(has_critical = FALSE, has_warnings = TRUE) {
  result <- ValidationResult$new("simulation.xlsx", "simulation")

  if (has_critical) {
    result$add_critical_error(
      "Structure Error",
      "Required sheet 'Scenarios' is missing",
      "File: scenarios.xlsx"
    )
    result$add_critical_error(
      "Missing Fields",
      "Mandatory column 'plotType' is missing",
      "Sheet: plotConfiguration"
    )
  }

  if (has_warnings) {
    result$add_warning(
      "Empty Data",
      "Sheet 'exportConfiguration' is empty",
      "Sheet: exportConfiguration",
      "Add export configurations to save plots"
    )
    result$add_warning(
      "Invalid Reference",
      "Plot grid 'grid3' references non-existent plotID",
      "Sheet: plotGrids",
      "Update plot grid or add missing plot"
    )
  }

  if (!has_critical) {
    # Simulate successful data import
    result$set_data(list(
      scenarios = data.frame(Scenario_name = c("Scenario1", "Scenario2")),
      plots = data.frame(plotID = c("plot1", "plot2"))
    ))
  }

  return(result)
}

# Test Case 1: Critical errors prevent import
cat("Test Case 1: File with critical errors\n")
cat("---------------------------------------\n")
result1 <- simulate_validation(has_critical = TRUE, has_warnings = TRUE)
if (result1$is_valid()) {
  cat("✅ Can import data\n")
  cat("Data available:", !is.null(result1$data), "\n")
} else {
  cat("❌ Cannot import - fix critical errors first\n")
  cat("Critical errors:", sum(sapply(result1$critical_errors, length)), "\n")
  cat("Warnings:", sum(sapply(result1$warnings, length)), "\n")
}

# Test Case 2: Warnings allow import
cat("\n\nTest Case 2: File with only warnings\n")
cat("-------------------------------------\n")
result2 <- simulate_validation(has_critical = FALSE, has_warnings = TRUE)
if (result2$is_valid()) {
  cat("✅ Can import data (with warnings)\n")
  cat("Data available:", !is.null(result2$data), "\n")
  cat("Warnings to review:", sum(sapply(result2$warnings, length)), "\n")
} else {
  cat("❌ Cannot import\n")
}

# Test Case 3: Clean file
cat("\n\nTest Case 3: Clean file (no issues)\n")
cat("------------------------------------\n")
result3 <- simulate_validation(has_critical = FALSE, has_warnings = FALSE)
if (result3$is_valid() && !result3$has_warnings) {
  cat("✅ Perfect! No issues found\n")
  cat("Data available:", !is.null(result3$data), "\n")
}

# Example 4: Integration with WarningHandler
cat("\n\n=================================================\n")
cat("Example 4: Integration with WarningHandler\n")
cat("=================================================\n\n")

# Source the data_structure file to get WarningHandler
source("data_structure.R")

# Create a WarningHandler instance
warning_handler <- WarningHandler$new()

# Add validation results
warning_handler$add_validation_result("scenarios", result1)
warning_handler$add_validation_result("plots", result2)

# Get summary
summary <- warning_handler$get_summary()
cat("Summary of all validations:\n")
cat("  Has critical errors:", summary$has_critical_errors, "\n")
cat("  Total critical errors:", summary$total_critical_errors, "\n")
cat("  Total warnings:", summary$total_warnings, "\n")
cat("  Affected files:", paste(summary$affected_files, collapse = ", "), "\n")

cat("\n\n=================================================\n")
cat("Validation System Test Complete!\n")
cat("=================================================\n")

# Usage Instructions
cat("\n📝 USAGE INSTRUCTIONS:\n")
cat("---------------------\n")
cat("1. When importing project configuration:\n")
cat("   - The system automatically validates all Excel files\n")
cat("   - Critical errors block import and show in red\n")
cat("   - Warnings allow import but show in yellow\n")
cat("   - Success shows in green\n\n")

cat("2. The warning modal now shows three tabs:\n")
cat("   - Summary: Overall validation status\n")
cat("   - Critical Errors: Must-fix issues (if any)\n")
cat("   - Warnings: Should-review issues (if any)\n\n")

cat("3. Icon changes based on severity:\n")
cat("   - 🔔 Bell (default, no issues)\n")
cat("   - ⚠️ Warning triangle (warnings only)\n")
cat("   - ❗ Exclamation triangle (critical errors)\n\n")

cat("4. Files with critical errors are NOT imported\n")
cat("5. Files with only warnings ARE imported\n")
cat("6. Clean files are imported silently\n")