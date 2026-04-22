#' Create a new blank gopheR database
#'
#' Copies the starter database from the gopheR package to a specified location.
#' The starter database includes all required spec tables (object_type, edge_spec, etc.)
#' but no actual data in the object, edge, workflow, or people tables.
#'
#' @param dest_path Character. Full path including filename for the new database.
#' @param overwrite Logical. If TRUE, overwrites existing file at dest_path.
#'
#' @returns Invisibly returns the destination path.
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a new project database
#' make_new_db("~/my_project/my_data.sqlite")
#'
#' # Set it as the active database
#' options(gopheR.db_path = "~/my_project")
#' options(gopheR.db_file = "my_data.sqlite")
#' }

make_new_db <- function(dest_path, overwrite = FALSE) {
  # Get starter database from gopheR
  starter <- system.file("extdata", "starter_db.sqlite", package = "gopheR")
  if (!nzchar(starter) || !file.exists(starter)) {
    cli::cli_abort(c(
      "Could not find starter database in {.pkg gopheR} package.",
      "i" = "Try reinstalling gopheR."
    ))
  }

  # Check if destination already exists
  if (file.exists(dest_path) && !overwrite) {
    cli::cli_abort(c(
      "File already exists at {.path {dest_path}}",
      "i" = "Set {.code overwrite = TRUE} to replace it."
    ))
  }

  # Create parent directory if needed
  dest_dir <- dirname(dest_path)
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
    cli::cli_alert_info("Created directory: {.path {dest_dir}}")
  }

  # Copy the database
  success <- file.copy(starter, dest_path, overwrite = overwrite)

  if (success) {
    cli::cli_alert_success("Blank database created at {.path {dest_path}}")
    cli::cli_alert_info("Set database path with:")
    cli::cli_code("options(gopheR.db_path = \"{dest_dir}\")")
    cli::cli_code("options(gopheR.db_file = \"{basename(dest_path)}\")")
  } else {
    cli::cli_abort("Failed to copy database to {.path {dest_path}}")
  }

  invisible(dest_path)
}
