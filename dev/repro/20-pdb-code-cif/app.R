pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #20 (GitHub #17): PDB codes without a legacy PDB file cannot
# be loaded. Needs network (RCSB).
# Launch from the project root:
#   shiny::runApp("dev/repro/20-pdb-code-cif", launch.browser = TRUE)

choices <- c(
  "1CRN (small, has a legacy .pdb file)" = "1crn",
  "3J9M (mitoribosome, no legacy .pdb file)" = "3j9m",
  "3J9M with format = \"cif\"" = "3j9m_cif",
  "4V6X (ribosome, no legacy .pdb file)" = "4v6x"
)

build <- function(choice) {
  switch(choice,
    "1crn"     = NGLVieweR("1CRN"),
    "3j9m"     = NGLVieweR("3J9M"),
    "3j9m_cif" = NGLVieweR("3J9M", format = "cif"),
    "4v6x"     = NGLVieweR("4V6X")
  ) %>% addRepresentation("cartoon")
}

ui <- fluidPage(
  titlePanel("Bug #20: PDB codes without a legacy PDB file cannot be loaded"),
  wellPanel(
    tags$b("What to look for"),
    tags$ol(
      tags$li("'1CRN': crambin appears, 46 residues, input$viewer_error is NULL ",
              "(before and after the fix)."),
      tags$li("Before the fix, '3J9M' and '4V6X': the viewer stays empty and input$viewer_error ",
              "says \"could not load structure 1 (rcsb://3J9M.pdb)\". RCSB has no .pdb file for ",
              "these large entries (404), only .cif. '3J9M with format = \"cif\"' gives exactly ",
              "the same error: the URL still ends in .pdb, because format was ignored for codes."),
      tags$li("After the fix: all four load and input$viewer_error is NULL. Without format the ",
              "URL is .pdb with a .cif fallback; with format = \"cif\" it is .cif directly. ",
              "The ribosomes are large: allow a few seconds.")
    )
  ),
  fluidRow(
    column(4,
      radioButtons("choice", "PDB code for renderNGLVieweR()", choices),
      h4("Debug"),
      verbatimTextOutput("debug")
    ),
    column(8, NGLVieweROutput("viewer", height = "500px"))
  )
)

server <- function(input, output, session) {
  widget <- reactive(build(input$choice))
  output$viewer <- renderNGLVieweR(widget())

  output$debug <- renderText({
    res <- input$viewer_residues
    err <- input$viewer_error
    paste0(
      "URL sent by R:  ", widget()$x$structures[[1]]$data, "\n",
      "fallback:       ", format(widget()$x$structures[[1]]$fallback), "\n",
      "format sent:    ", format(widget()$x$structures[[1]]$file_ext), "\n",
      "residues loaded: ", if (is.null(res)) "none" else nrow(res), "\n",
      "input$viewer_error:\n  ", if (is.null(err)) "NULL" else err
    )
  })
}

shinyApp(ui, server)
