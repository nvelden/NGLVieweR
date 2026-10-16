pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #8: structure load failures are silent.
# Launch from the project root:
#   shiny::runApp("dev/repro/08-load-failure", launch.browser = TRUE)

fixtures <- normalizePath("../../../tests/testthat/fixtures")

choices <- c(
  "1CRN from RCSB (works)" = "good_code",
  "1crn.pdb fixture (works)" = "good_file",
  "XXXX from RCSB (does not exist)" = "bad_code",
  "broken.pdb (not a structure)" = "bad_file",
  "1crn.pdb + XXXX (one good, one bad)" = "mixed"
)

build <- function(choice) {
  switch(choice,
    good_code = NGLVieweR("1CRN"),
    good_file = NGLVieweR(file.path(fixtures, "1crn.pdb")),
    bad_code  = NGLVieweR("XXXX"),
    bad_file  = NGLVieweR(file.path(fixtures, "broken.pdb")),
    mixed     = NGLVieweR(file.path(fixtures, "1crn.pdb")) %>% addStructure("XXXX")
  ) %>% addRepresentation("cartoon")
}

ui <- fluidPage(
  titlePanel("Bug #8: structure load failures are silent"),
  wellPanel(
    tags$b("What to look for"),
    tags$ol(
      tags$li("Pick '1CRN from RCSB': the viewer shows crambin and the inputs below are filled (46 residues)."),
      tags$li("Pick 'XXXX from RCSB': the viewer is empty, but input$viewer_sequence still holds ",
              "crambin's 46 residues and 'last update' does not change. The app cannot tell that loading failed."),
      tags$li("Pick '1crn.pdb + XXXX': one structure is fine, but nothing is shown and no inputs are sent."),
      tags$li("input$viewer_error does not exist yet (always NULL).")
    )
  ),
  fluidRow(
    column(4,
      radioButtons("choice", "Structure(s) for renderNGLVieweR()", choices),
      h4("What Shiny receives"),
      verbatimTextOutput("inputs")
    ),
    column(8, NGLVieweROutput("viewer", height = "450px"))
  )
)

server <- function(input, output, session) {
  last_update <- reactiveVal("never")
  observeEvent(input$viewer_sequence, last_update(format(Sys.time(), "%H:%M:%S")))

  output$viewer <- renderNGLVieweR(build(input$choice))

  output$inputs <- renderText({
    seq <- input$viewer_sequence
    paste0(
      "input$viewer_sequence: ", length(unlist(seq)), " residues",
      if (length(seq)) paste0(" (", substr(paste(unlist(seq), collapse = ""), 1, 20), "...)") else "", "\n",
      "  last update: ", last_update(), "\n",
      "input$viewer_PDB: ", length(input$viewer_PDB), " structure(s)\n",
      "input$viewer_rendering: ", format(input$viewer_rendering), "\n",
      "input$viewer_error: ", format(input$viewer_error)
    )
  })
}

shinyApp(ui, server)
