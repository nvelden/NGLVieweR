#'
#' Run NGLVieweR example Shiny app
#'
#' @description
#' Launch an example to demonstrate how to use \code{NGLvieweR} in Shiny.
#'
#' @param example Example type for which to see an example, possible values are:
#' "basic", "API", "addSelection", "removeSelection", "snapshot",
#' "updateAnimation", "updateColor", "updateFocus", "updateFullscreen",
#' "updateRepresentation", "updateSelection", "updateStage", "updateVisibility" and
#' "updateZoomMove".
#' @examples
#'
#' if (interactive()) {
#'
#' # Basic example
#' NGLVieweR_example("basic")
#'
#' # Example with API calls
#' NGLVieweR_example("API")
#'
#' # Function specific example
#' NGLVieweR_example("addSelection")
#' }
#'
#'@importFrom shiny shinyAppDir
#'
#'@export
NGLVieweR_example <- function(example = "basic") {
  example <- match.arg(
    arg = example,
    choices = c("basic", "API", "addSelection", "removeSelection", "snapshot",
                "updateAnimation", "updateColor", "updateFocus", "updateFullscreen",
                "updateRepresentation", "updateSelection", "updateStage", "updateVisibility",
                "updateZoomMove"),
    several.ok = FALSE
  )
  path <- file.path("examples", example)
  shinyAppDir(
    appDir = system.file(path, package="NGLVieweR", mustWork=TRUE),
    options = list(display.mode = "showcase")
  )
}
