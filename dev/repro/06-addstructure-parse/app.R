pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #6: addStructure() and NGLVieweR() parse input differently.
# Launch from the project root:
#   shiny::runApp("dev/repro/06-addstructure-parse", launch.browser = TRUE)
#
# The app copies 1crn.pdb into a temporary folder and works from there, so
# "1crn.pdb" is a file in the working directory (8 characters long).

fixtures <- normalizePath("../../../tests/testthat/fixtures")
work <- file.path(tempdir(), "repro-06")
dir.create(work, showWarnings = FALSE)
file.copy(file.path(fixtures, "1crn.pdb"), work, overwrite = TRUE)
setwd(work)
pdb_text <- paste(readLines("1crn.pdb"), collapse = "\n")

# The structure entry each function creates for the same input.
summarise <- function(call, s) {
  data.frame(
    call = call,
    type = s$type,
    file_ext = if (is.null(s$file_ext)) "NULL" else s$file_ext,
    data = if (s$type == "code") s$data else paste0(substr(s$data, 1, 24), "..."),
    check.names = FALSE
  )
}
try_struct <- function(expr) tryCatch(expr, error = function(e) list(type = "ERROR", file_ext = NULL, data = conditionMessage(e)))
via_nglviewer <- function(...) try_struct(NGLVieweR(...)$x$structures[[1]])
via_addstructure <- function(...) try_struct((NGLVieweR("1CRN") %>% addStructure(...))$x$structures[[2]])

inputs <- list(
  list(label = '"1crn.pdb" (file in working dir, 8 chars)', args = list("1crn.pdb")),
  list(label = 'full path to 1crn.pdb', args = list(normalizePath("1crn.pdb"))),
  list(label = '"1crn.pdb", format = ".pdb" (leading dot)', args = list("1crn.pdb", format = ".pdb")),
  list(label = 'PDB code "1CRN"', args = list("1CRN")),
  list(label = 'file contents, format = "pdb"', args = list(pdb_text, format = "pdb"))
)

comparison <- do.call(rbind, lapply(inputs, function(i) {
  a <- do.call(via_nglviewer, i$args)
  b <- do.call(via_addstructure, i$args)
  rbind(
    cbind(input = i$label, summarise("NGLVieweR()", a)),
    cbind(input = "", summarise("addStructure()", b)),
    cbind(input = "", data.frame(call = if (identical(a[c("type", "file_ext", "data")], b[c("type", "file_ext", "data")])) "same" else "DIFFERENT",
                                 type = "", file_ext = "", data = ""))
  )
}))

# Built here, while the temporary folder is the working directory (Shiny
# runs server code from the app folder).
left_widget <- NGLVieweR("1crn.pdb") %>%
  addRepresentation("cartoon", param = list(color = "red"))
right_widget <- NGLVieweR(pdb_text, format = "pdb") %>%
  addRepresentation("cartoon", param = list(color = "red")) %>%
  addStructure("1crn.pdb") %>%
  addRepresentation("cartoon", param = list(color = "green"))

ui <- fluidPage(
  titlePanel("Bug #6: addStructure() and NGLVieweR() parse input differently"),
  wellPanel(
    tags$b("What to look for"),
    tags$ol(
      tags$li("Table: the same input gives a different structure entry in NGLVieweR() and addStructure() ",
              "(rows marked DIFFERENT)."),
      tags$li('"1crn.pdb": NGLVieweR() reads the file; addStructure() treats it as PDB code ',
              "and asks RCSB for rcsb://1crn.pdb.pdb."),
      tags$li('format = ".pdb": NGLVieweR() removes the dot; addStructure() keeps it.'),
      tags$li('Viewers: left NGLVieweR("1crn.pdb") shows crambin. Right ',
              'NGLVieweR(<PDB text>) %>% addStructure("1crn.pdb") should show crambin twice ',
              "(red + green), but the viewer stays empty: the green one is requested from RCSB as ",
              "'1crn.pdb.pdb', that fails, and the failure also stops the red one (that part is bug #8).")
    )
  ),
  h4("Structure entry created for the same input"),
  tableOutput("table"),
  fluidRow(
    column(6, h4('NGLVieweR("1crn.pdb")'), NGLVieweROutput("left", height = "350px")),
    column(6, h4('... %>% addStructure("1crn.pdb")'), NGLVieweROutput("right", height = "350px"))
  )
)

server <- function(input, output, session) {
  output$table <- renderTable(comparison)
  output$left <- renderNGLVieweR(left_widget)
  output$right <- renderNGLVieweR(right_widget)
}

shinyApp(ui, server)
