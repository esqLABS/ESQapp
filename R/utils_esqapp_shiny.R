#' Load .esqapp file in Shiny application
#'
#' @param zip_path Path to the uploaded .esqapp file
#' @param file_name Original filename
#' @param r Reactive values object to store project root and temp directory
#'
#' @return Project configuration object or NULL on error
#' @noRd
load_esqapp_shiny <- function(zip_path, file_name, r) {
  file_ext <- tools::file_ext(file_name)
  if (!file_ext %in% c("esqapp", "zip")) {
    shiny::showNotification("Please upload a valid .esqapp or .zip file", type = "error", duration = 8)
    return(NULL)
  }

  pc <- shiny::withProgress(message = 'Loading project...', value = 0, {
    shiny::incProgress(0.2, detail = "Validating file...")

    validation_result <- tryCatch({
      file_list <- unzip(zip_path, list = TRUE)
      has_config <- any(grepl("ProjectConfiguration\\.xlsx$", file_list$Name, ignore.case = TRUE))

      if (!has_config) {
        shiny::showNotification("Invalid .esqapp: ProjectConfiguration.xlsx file not found", type = "error", duration = 8)
        return(NULL)
      }
      TRUE
    }, error = function(e) {
      shiny::showNotification(paste0("Invalid .esqapp file: ", e$message), type = "error", duration = 8)
      return(NULL)
    })

    if (is.null(validation_result)) {
      return(NULL)
    }

    shiny::incProgress(0.4, detail = "Extracting files...")

    temp_dir <- file.path(tempdir(), paste0("esqapp_", format(Sys.time(), "%Y%m%d_%H%M%S")))
    dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)

    extract_result <- tryCatch({
      unzip(zip_path, exdir = temp_dir)
      TRUE
    }, error = function(e) {
      shiny::showNotification(paste0("Failed to extract .esqapp: ", e$message), type = "error", duration = 8)
      return(NULL)
    })

    if (is.null(extract_result)) {
      return(NULL)
    }

    shiny::incProgress(0.6, detail = "Finding configuration...")

    config_file <- list.files(temp_dir,
      pattern = "ProjectConfiguration\\.xlsx$",
      recursive = TRUE,
      full.names = TRUE,
      ignore.case = TRUE
    )[1]

    if (is.na(config_file)) {
      shiny::showNotification("ProjectConfiguration.xlsx file not found after extraction", type = "error", duration = 8)
      return(NULL)
    }

    shiny::incProgress(0.8, detail = "Loading configuration...")

    project_root <- dirname(config_file)

    old_wd <- getwd()
    setwd(project_root)

    pc <- tryCatch({
      esqlabsR::createDefaultProjectConfiguration(path = basename(config_file))
    }, error = function(e) {
      setwd(old_wd)
      shiny::showNotification(paste0("Failed to load configuration: ", e$message), type = "error", duration = 10)
      return(NULL)
    })

    setwd(old_wd)

    if (is.null(pc)) {
      return(NULL)
    }

    r$config$project_root <- project_root
    r$config$temp_dir <- temp_dir

    shiny::incProgress(1, detail = "Complete!")

    return(pc)
  })

  if (!is.null(pc)) {
    shiny::showNotification("Project loaded successfully!", type = "message", duration = 5)
  }

  return(pc)
}


#' Create .esqapp file for download
#'
#' @param original_project_root Path to the original project root directory
#' @param r Reactive values object containing data
#' @param output_file Path where to save the .esqapp file
#' @param DROPDOWN_COLUMN_TYPE_LIST List of dropdown column types
#' @param NUMERIC_COLUMN_TYPE_LIST List of numeric column types
#'
#' @return TRUE on success, FALSE on failure
#' @noRd
create_esqapp_shiny <- function(original_project_root, r, output_file,
                                DROPDOWN_COLUMN_TYPE_LIST, NUMERIC_COLUMN_TYPE_LIST) {

  # Determine file extension for notifications
  file_ext <- tools::file_ext(output_file)
  if (file_ext == "") file_ext <- "esqapp"

  shiny::withProgress(message = paste0('Creating .', file_ext, ' file...'), value = 0, {
    shiny::incProgress(0.2, detail = "Preparing files...")

    temp_export_dir <- file.path(tempdir(), paste0("esqapp_export_", format(Sys.time(), "%Y%m%d_%H%M%S")))
    dir.create(temp_export_dir, showWarnings = FALSE, recursive = TRUE)

    export_success <- TRUE

    shiny::incProgress(0.3, detail = "Recreating directory structure...")

    tryCatch({
      all_dirs <- list.dirs(original_project_root, full.names = FALSE, recursive = TRUE)
      all_dirs <- all_dirs[all_dirs != ""]

      for (dir_path in all_dirs) {
        dest_dir <- file.path(temp_export_dir, dir_path)
        if (!dir.exists(dest_dir)) {
          dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
        }
      }
    }, error = function(e) {
      message("Error creating directory structure: ", e$message)
    })

    shiny::incProgress(0.4, detail = "Copying project files...")

    tryCatch({
      config_files_to_export <- sapply(r$data$get_config_files(), function(cf) {
        r$data[[cf]]$file_path
      })

      config_files_normalized <- gsub("\\\\", "/", config_files_to_export)

      all_files <- list.files(original_project_root,
                             full.names = FALSE,
                             recursive = TRUE,
                             all.files = FALSE)

      for (rel_path in all_files) {
        src_file <- file.path(original_project_root, rel_path)
        dest_file <- file.path(temp_export_dir, rel_path)

        src_file_normalized <- gsub("\\\\", "/", src_file)

        if (src_file_normalized %in% config_files_normalized) {
          next
        }

        dest_dir <- dirname(dest_file)
        if (!dir.exists(dest_dir)) {
          dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
        }

        if (file.exists(src_file) && !file.info(src_file)$isdir) {
          file.copy(src_file, dest_file, overwrite = TRUE)
        }
      }
    }, error = function(e) {
      message("Error copying project files: ", e$message)
    })

    shiny::incProgress(0.6, detail = "Exporting modified data...")

    for (config_file in r$data$get_config_files()) {
      original_file_path <- r$data[[config_file]]$file_path

      rel_path <- if (startsWith(original_file_path, original_project_root)) {
        norm_root <- gsub("\\\\", "/", original_project_root)
        norm_path <- gsub("\\\\", "/", original_file_path)
        sub(paste0("^", norm_root, "/?"), "", norm_path)
      } else {
        basename(original_file_path)
      }

      export_path <- file.path(temp_export_dir, rel_path)

      sheet_list <- list()

      for (sheet in r$data[[config_file]]$sheets) {
        df <- r$data[[config_file]][[sheet]]$modified
        dropdown_cols <- DROPDOWN_COLUMN_TYPE_LIST[[config_file]][[sheet]]
        if (!is.null(dropdown_cols)) {
          df[dropdown_cols] <- lapply(df[dropdown_cols], function(col) {
            replace(col, col == "--NONE--", NA)
          })
        }
        numeric_cols <- NUMERIC_COLUMN_TYPE_LIST[[config_file]][[sheet]]
        if (!is.null(numeric_cols)) {
          existing_numeric_cols <- intersect(numeric_cols, names(df))
          if (length(existing_numeric_cols) > 0) {
            df[existing_numeric_cols] <- suppressWarnings(
              lapply(df[existing_numeric_cols], function(col) {
                as.numeric(as.character(col))
              })
            )
          }
        }
        sheet_list[[sheet]] <- df
      }

      tryCatch({
        rio::export(x = sheet_list, file = export_path)
      }, error = function(e) {
        message("Error exporting ", config_file, ": ", e$message)
        export_success <<- FALSE
      })
    }

    if (!export_success) {
      shiny::showNotification("Failed to export some files", type = "error", duration = 8)
      return(FALSE)
    }

    shiny::incProgress(0.7, detail = "Creating archive...")

    tryCatch({
      old_wd_zip <- getwd()
      setwd(temp_export_dir)

      files_to_zip <- list.files(".", recursive = TRUE, all.files = FALSE, include.dirs = FALSE)

      if (length(files_to_zip) == 0) {
        setwd(old_wd_zip)
        shiny::showNotification("No files to export", type = "error", duration = 8)
        return(FALSE)
      }

      utils::zip(zipfile = output_file, files = files_to_zip, flags = "-r9Xq")

      setwd(old_wd_zip)

      shiny::incProgress(0.9, detail = "Cleaning up...")

      unlink(temp_export_dir, recursive = TRUE)

      shiny::incProgress(1, detail = "Complete!")
    }, error = function(e) {
      tryCatch(setwd(old_wd_zip), error = function(e2) {})
      shiny::showNotification(paste0("Failed to create .", file_ext, ": ", e$message), type = "error", duration = 10)
      return(FALSE)
    })
  })

  shiny::showNotification(paste0(".", file_ext, " file created successfully!"), type = "message", duration = 5)
  return(TRUE)
}