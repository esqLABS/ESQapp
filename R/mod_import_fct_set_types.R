type_columns <- function(r, df, config_file, sheet) {
  types <- r$data[[config_file]][[sheet]]$columns

  if (is.null(types)) {
    types <- r$data[[config_file]][["Generic"]]
  }

  columns <- colnames(df)

  for (column in columns) {
    column_info <- types[[column]]

    if (!is.null(column_info$type)) {
      df[[column]] <- switch(column_info$type,
        "character" = df[[column]],
        "list" = df[[column]],
        "numeric" = as.numeric(df[[column]]),
        "logical" = as.logical(df[[column]]),
        "factor" = add_fixed_factor_levels(df[[column]], column_info)
      )
    }
  }

  return(df)
}

add_fixed_factor_levels <- function(column, column_info) {
  if (!is.null(column_info$fixed_levels)) {
    column <- factor(column, levels = column_info$fixed_levels)
  } else {
    column <- as.factor(column)
  }

  return(column)
}
