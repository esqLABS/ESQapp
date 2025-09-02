test_that("Project Configuration can be created from Excel configuration file", {
  projectConfiguration <- get_projectConfiguration()

  expect_s3_class(projectConfiguration, "ProjectConfiguration")
  expect_s3_class(projectConfiguration, "R6")

  warn <- attr(projectConfiguration, "warning", exact = TRUE)

  if (is.null(warn)) {
    succeed()
  } else {
    expect_true(
      grepl("older version|recommended to update", warn, ignore.case = TRUE),
      info = paste("Unexpected warning:", warn)
    )
  }
})


test_that("All scenarios can be created from Excel configuration (scenarioNames = NULL)", {
  projectConfiguration <- get_projectConfiguration()

  scenarios <- esqlabsR::readScenarioConfigurationFromExcel(
    scenarioNames = NULL,
    projectConfiguration = projectConfiguration
  )

  expect_type(scenarios, "list")
  expect_true(length(scenarios) > 0)
  expect_true(!is.null(names(scenarios)))
  expect_true(all(nzchar(names(scenarios))))
  lapply(scenarios, function(x) {
    expect_s3_class(x, "ScenarioConfiguration")
    expect_s3_class(x, "R6")
  })

})
