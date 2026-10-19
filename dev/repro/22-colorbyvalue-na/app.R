pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #22: colorByValue() gives missing values the middle palette
# color instead of na_color when both ends of the domain are equal.
# Works offline (fixture file). Launch from the project root:
#   shiny::runApp("dev/repro/22-colorbyvalue-na", launch.browser = TRUE)

pdb <- normalizePath("../../../tests/testthat/fixtures/1crn.pdb")

# Residues 1-23 have a score, 24-46 have none (NA).
cases <- list(
  "A: one score (5) for 1-23, NA for 24-46" = c(rep(5, 23), rep(NA, 23)),
  "B: scores 5 and 6 for 1-23, NA for 24-46 (works)" = c(rep(5:6, length.out = 23), rep(NA, 23)),
  "C: one score (5) for 1-23, NaN for 24-46" = c(rep(5, 23), rep(NaN, 23))
)

ui <- fluidPage(
  titlePanel("Bug #22: colorByValue() colors NA like a value when the domain ends are equal"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Palette blue - white - red, na_color \"green\" (so a missing value is easy ",
           "to spot). Residues 1-23 have a score, residues 24-46 have none."),
    tags$ol(
      tags$li("A: the second half of the chain should be green (no score). It is white, ",
              "like the scored residues: with only one distinct score the domain is ",
              "c(5, 5) and every residue gets the middle color."),
      tags$li("B: with two different scores the second half is green, as it should be."),
      tags$li("C: same as A with NaN.")
    ),
    tags$p("The table shows the colors colorByValue() computed in R.")
  ),
  fluidRow(
    column(4,
      radioButtons("case", "Scores", names(cases)),
      h4("Colors from colorByValue()"),
      tableOutput("colors")
    ),
    column(8, NGLVieweROutput("viewer", height = "550px"))
  )
)

server <- function(input, output, session) {
  colors <- reactive({
    scores <- data.frame(chain = "A", resno = 1:46, value = cases[[input$case]])
    colorByValue(scores, na_color = "green")
  })

  output$viewer <- renderNGLVieweR({
    NGLVieweR(pdb) %>%
      addRepresentation("cartoon", param = list(color = colors()))
  })

  output$colors <- renderTable({
    v <- cases[[input$case]]
    cl <- colors()
    data.frame(
      residues = c("1-23", "24-46"),
      value = c(paste(unique(v[1:23]), collapse = ", "), as.character(v[24])),
      color = c(paste(unique(cl$color[1:23]), collapse = ", "), cl$color[24]),
      expected = c("palette colors", paste0(cl$na_color, " (na_color)"))
    )
  })
}

shinyApp(ui, server)
