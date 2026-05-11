#' Render the Quarto site bundled with gopherDen
#'
#' This renders the Quarto project located at `inst/quarto/`.
#' It works both when the package is installed (uses `system.file()`)
#' and during development (uses the repo's `inst/quarto/`).
#'
#' @param site_dir Path to the Quarto site directory. Defaults to `inst/quarto`.
#'   If the package is installed, uses `system.file("quarto", package = "gopherDen")`.
#' @param output_dir Where to write the rendered site. If NULL, Quarto uses its default
#'   (usually `_site/` inside the site directory).
#' @param quiet If TRUE, suppress Quarto output. Default FALSE.
#'
#' @returns Invisibly returns the path to the rendered output directory.
#'
#' @examples
#' \dontrun{
#' # Render the site during development
#' render_site()
#'
#' # Render to a custom output directory
#' render_site(output_dir = "docs")
#' }
#'
#' @export
render_site <- function(site_dir = NULL, output_dir = NULL, quiet = FALSE) {

  # Check if quarto CLI is available
  if (Sys.which("quarto") == "") {
    stop("Quarto CLI not found on PATH. Install from https://quarto.org", call. = FALSE)
  }

  # Auto-detect site directory
  if (is.null(site_dir)) {
    # First try development location
    if (file.exists("inst/quarto")) {
      site_dir <- "inst/quarto"
    } else {
      # Try installed package location
      pkg_dir <- system.file("quarto", package = "gopherDen")
      if (nzchar(pkg_dir) && file.exists(pkg_dir)) {
        site_dir <- pkg_dir
      } else {
        stop("Cannot find Quarto site directory. Provide site_dir parameter.", call. = FALSE)
      }
    }
  }

  # Normalize path
  site_dir <- normalizePath(site_dir, mustWork = TRUE)

  # Build quarto command arguments
  args <- c("render", site_dir)

  if (!is.null(output_dir)) {
    args <- c(args, "--output-dir", normalizePath(output_dir, mustWork = FALSE))
  }

  # Disable cache for fresh renders
  args <- c(args, "--no-cache")

  # Render
  if (!quiet) {
    message("Rendering Quarto site at: ", site_dir)
  }

  status <- system2("quarto", args = args, stdout = "", stderr = "")

  if (length(status) > 0 && status[1] != 0) {
    stop("Quarto render failed with status ", status[1], call. = FALSE)
  }

  # Return output directory path
  output_path <- if (is.null(output_dir)) {
    file.path(site_dir, "_site")
  } else {
    normalizePath(output_dir, mustWork = FALSE)
  }

  if (!quiet) {
    message("Site rendered successfully to: ", output_path)
  }

  invisible(output_path)
}


#' Open the rendered site in a web browser
#'
#' Opens the main index.html file from the rendered site.
#'
#' @param site_dir Path to the Quarto site directory. Defaults to `inst/quarto`.
#'
#' @returns Invisibly returns TRUE if successful.
#'
#' @examples
#' \dontrun{
#' # Render and view the site
#' render_site()
#' view_site()
#' }
#'
#' @export
view_site <- function(site_dir = NULL) {

  if (is.null(site_dir)) {
    if (file.exists("inst/quarto/_site/index.html")) {
      site_dir <- "inst/quarto"
    } else {
      pkg_dir <- system.file("quarto", package = "gopherDen")
      if (nzchar(pkg_dir) && file.exists(file.path(pkg_dir, "_site/index.html"))) {
        site_dir <- pkg_dir
      } else {
        stop("Cannot find rendered site. Run render_site() first.", call. = FALSE)
      }
    }
  }

  index_path <- file.path(site_dir, "_site", "index.html")

  if (!file.exists(index_path)) {
    stop("Site not rendered. Run render_site() first.", call. = FALSE)
  }

  utils::browseURL(index_path)

  invisible(TRUE)
}
