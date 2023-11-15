# Building a Prod-Ready, Robust Shiny Application.
#
# README: each step of the dev files is optional, and you don't have to
# fill every dev scripts before getting started.
# 01_start.R should be filled at start.
# 02_dev.R should be used to keep track of your development during the project.
# 03_deploy.R should be used once you need to deploy your app.
#
#
###################################
#### CURRENT FILE: DEV SCRIPT #####
###################################

# Engineering

## Dependencies ----

download.file("https://github.com/Open-Systems-Pharmacology/rClr/releases/download/v0.9.2/rClr_0.9.2.zip", "./renv/rClr_0.9.2.zip")

renv::install("./renv/rClr_0.9.2.zip")
renv::install("usethis")
renv::install("remotes")
usethis::use_package("golem")
remotes::install_github("esqLABS/esqlabsR")
usethis::use_dev_package("esqlabsR", remote = "esqLABS/esqlabsR")
usethis::use_package("bslib")
usethis::use_package("shinyFiles")
usethis::use_package("rio")
usethis::use_package("validate")
usethis::use_package("fs")
usethis::use_dev_package("datamods", remote = "dreamrs/datamods")
usethis::use_package("devtools", type = "Suggest")
usethis::use_package("attachment", type = "Suggest")
usethis::use_package("styler", type = "Suggest")
usethis::use_dev_package("covrpage", type = "Suggest", remote = "yonicd/covrpage")
usethis::use_package("spelling", type = "Suggest")
usethis::use_package("covrpage", type = "Suggest")
usethis::use_package("rhub", type = "Suggest")
usethis::use_package("rsconnect", type = "Suggest")

## Amend DESCRIPTION with dependencies read from package code parsing
# install.packages('attachment') # if needed.
attachment::att_amend_desc()


## Add modules ----
## Create a module infrastructure in R/
golem::add_module(name = "sidebar")
golem::add_module(name = "main_panel")
golem::add_module(name = "data_structure")
golem::add_module(name = "import")
golem::add_module(name = "export")
golem::add_module(name = "edit_table")
golem::add_module(name = "table_tab")
golem::add_module(name = "tab_scenarios")
golem::add_module(name = "tab_individuals")
golem::add_module(name = "tab_populations")
golem::add_module(name = "tab_models")

## Add helper functions ----
## Creates fct_* and utils_*
golem::add_fct("helpers", with_test = TRUE)
golem::add_utils("helpers", with_test = TRUE)

## External resources
## Creates .js and .css files at inst/app/www
# golem::add_js_file("script")
# golem::add_js_handler("handlers")
# golem::add_css_file("custom")
# golem::add_sass_file("custom")

## Add internal datasets ----
## If you have data in your package
usethis::use_data_raw(name = "my_dataset", open = FALSE)

## Tests ----
## Add one line by test you want to create
usethis::use_test("app")

# Documentation


## Pkgdown ----
pkgdown::init_site()

## Vignette ----
usethis::use_vignette("shinyScenarioEditor")
usethis::use_vignette("appDesign")
devtools::build_vignettes()

## Code Coverage----
## Set the code coverage service ("codecov" or "coveralls")
usethis::use_coverage()

# Create a summary readme for the testthat subdirectory
covrpage::covrpage()

## CI ----
## Use this part of the script if you need to set up a CI
## service for your application
##
## (You'll need GitHub there)
usethis::use_github()

# GitHub Actions
usethis::use_github_action()
# Chose one of the three
# See https://usethis.r-lib.org/reference/use_github_action.html
usethis::use_github_action_check_release()
usethis::use_github_action_check_standard()
usethis::use_github_action_check_full()
# Add action for PR
usethis::use_github_action_pr_commands()

# Travis CI
usethis::use_travis()
usethis::use_travis_badge()

# AppVeyor
usethis::use_appveyor()
usethis::use_appveyor_badge()

# Circle CI
usethis::use_circleci()
usethis::use_circleci_badge()

# Jenkins
usethis::use_jenkins()

# GitLab CI
usethis::use_gitlab_ci()

# You're now set! ----
# go to dev/03_deploy.R
rstudioapi::navigateToFile("dev/03_deploy.R")
