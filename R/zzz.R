.onLoad <- function(libname, pkgname) {
  # Builds the data frame for input$<id>_residues (see .residues_input())
  shiny::registerInputHandler("NGLVieweR.residues", .residues_input, force = TRUE)
}

.onUnload <- function(libpath) {
  shiny::removeInputHandler("NGLVieweR.residues")
}
