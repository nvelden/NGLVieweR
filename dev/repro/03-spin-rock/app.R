pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #3: spin and rock never switch off on re-render.
# Also shows the related finding that stageParameters() survive re-renders.
# Launch from the project root:
#   shiny::runApp("dev/repro/03-spin-rock", launch.browser = TRUE)

pdb <- normalizePath("../../../tests/testthat/fixtures/1crn.pdb")

debug_js <- HTML("
$(document).on('shiny:connected', function() {
  setInterval(function() {
    var w = HTMLWidgets.find('#viewer');
    if (!w) return;
    var stage = w.getStage();
    Shiny.setInputValue('debug', {
      spinning: !stage.spinAnimation.paused,
      rocking: !stage.rockAnimation.paused,
      background: stage.parameters.backgroundColor
    });
  }, 300);
});
")

ui <- fluidPage(
  tags$head(tags$script(debug_js)),
  titlePanel("Bug #3: spin and rock never switch off on re-render"),
  wellPanel(
    tags$b("What to look for"),
    tags$ol(
      tags$li("Tick 'spin': the molecule spins and the debug panel says spinning = TRUE."),
      tags$li("Untick 'spin': renderNGLVieweR() re-runs with setSpin(FALSE), ",
              "but the molecule keeps spinning (spinning stays TRUE)."),
      tags$li("Same for 'rock'. Tick both: only one can run (NGL stops the other)."),
      tags$li("Related: tick 'white background' then untick it. ",
              "The R code no longer sets a background, but it stays white (NGL's default is black).")
    )
  ),
  fluidRow(
    column(4,
      checkboxInput("spin", "setSpin(input$spin)", FALSE),
      checkboxInput("rock", "setRock(input$rock)", FALSE),
      checkboxInput("white", "stageParameters(backgroundColor = 'white') if ticked", FALSE),
      h4("Debug panel"),
      tableOutput("debug")
    ),
    column(8, NGLVieweROutput("viewer", height = "500px"))
  )
)

server <- function(input, output, session) {
  renders <- reactiveVal(0)

  output$viewer <- renderNGLVieweR({
    isolate(renders(renders() + 1))
    w <- NGLVieweR(pdb) %>%
      addRepresentation("cartoon") %>%
      setSpin(input$spin) %>%
      setRock(input$rock)
    if (input$white) w <- w %>% stageParameters(backgroundColor = "white")
    w
  })

  output$debug <- renderTable({
    d <- input$debug
    req(d)
    data.frame(
      measure = c("renderNGLVieweR() runs",
                  "R asked for: spin", "stage: spinning",
                  "R asked for: rock", "stage: rocking",
                  "R asked for: background", "stage: background"),
      value = c(renders(),
                input$spin, d$spinning,
                input$rock, d$rocking,
                if (input$white) "white" else "(not set)", d$background)
    )
  })
}

shinyApp(ui, server)
