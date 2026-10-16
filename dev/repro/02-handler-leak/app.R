pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #2: event handlers pile up on every re-render.
# Launch from the project root:
#   shiny::runApp("dev/repro/02-handler-leak", launch.browser = TRUE)

pdb <- normalizePath("../../../tests/testthat/fixtures/1crn.pdb")

# Debug JS: counts how often the widget sends each input, and polls the
# number of listeners on the NGL signals NGLVieweR subscribes to.
debug_js <- HTML("
$(document).on('shiny:connected', function() {
  window.sendCounts = {};
  var orig = Shiny.onInputChange;
  Shiny.onInputChange = function(name, value, opts) {
    window.sendCounts[name] = (window.sendCounts[name] || 0) + 1;
    return orig.apply(this, arguments);
  };
  // Shiny.setInputValue is the same function; keep the alias pointing to the wrapper.
  Shiny.setInputValue = Shiny.onInputChange;

  window.resizeCalls = 0;
  setInterval(function() {
    var w = HTMLWidgets.find('#viewer');
    if (!w) return;
    var stage = w.getStage();
    if (!stage.__spied) {
      var origResize = stage.handleResize;
      stage.handleResize = function() { window.resizeCalls++; return origResize.apply(this, arguments); };
      stage.__spied = true;
    }
    Shiny.setInputValue('debug', {
      clicked: stage.signals.clicked.getNumListeners(),
      countChanged: stage.tasks.signals.countChanged.getNumListeners(),
      selectionSends: window.sendCounts['viewer_selection'] || 0,
      selAroundSends: window.sendCounts['viewer_selAround'] || 0,
      resizeCalls: window.resizeCalls
    });
  }, 500);
});
$(document).on('click', '#reset', function() {
  window.sendCounts = {};
  window.resizeCalls = 0;
});
$(document).on('click', '#fireResize', function() {
  window.resizeCalls = 0;
  window.dispatchEvent(new Event('resize'));
});
")

ui <- fluidPage(
  tags$head(tags$script(debug_js),
            tags$style("#server { white-space: pre-wrap; word-break: break-all; }")),
  titlePanel("Bug #2: event handlers pile up on every re-render"),
  wellPanel(
    tags$b("What to look for"),
    tags$ol(
      tags$li("Note the listener counts in the debug panel."),
      tags$li("Switch the representation or change the proximity a few times. ",
              "Each switch re-runs renderNGLVieweR(). Both listener counts go up by 1 every time."),
      tags$li("Press 'Reset counters', then click ONE atom in the viewer. ",
              "'_selection sends' shows how many times that single click was sent ",
              "(1 when correct, N after N renders)."),
      tags$li("Press 'Fire window resize': handleResize runs once per render so far, not once.")
    )
  ),
  fluidRow(
    column(4,
      selectInput("rep", "Representation (re-renders)", c("cartoon", "ball+stick", "spacefill")),
      numericInput("proximity", "selectionParameters(proximity =) (re-renders)", 3, min = 1, max = 10),
      actionButton("reset", "Reset counters"),
      actionButton("fireResize", "Fire window resize"),
      h4("Debug panel"),
      tableOutput("debug"),
      h4("Server side"),
      verbatimTextOutput("server")
    ),
    column(8, NGLVieweROutput("viewer", height = "500px"))
  )
)

server <- function(input, output, session) {
  renders <- reactiveVal(0)
  selection_runs <- reactiveVal(0)

  output$viewer <- renderNGLVieweR({
    isolate(renders(renders() + 1))
    NGLVieweR(pdb) %>%
      addRepresentation(input$rep, param = list(name = "rep")) %>%
      selectionParameters(proximity = input$proximity, level = "residue")
  })

  observeEvent(input$viewer_selection, selection_runs(selection_runs() + 1))
  observeEvent(input$reset, selection_runs(0))

  output$debug <- renderTable({
    d <- input$debug
    req(d)
    data.frame(
      measure = c("renderNGLVieweR() runs",
                  "stage.signals.clicked listeners",
                  "stage.tasks.signals.countChanged listeners",
                  "_selection sends (since reset)",
                  "_selAround sends (since reset)",
                  "handleResize calls (last resize)"),
      value = as.integer(c(renders(), d$clicked, d$countChanged, d$selectionSends,
                           d$selAroundSends, d$resizeCalls))
    )
  })

  output$server <- renderText({
    paste0(
      "observeEvent(input$viewer_selection) runs since reset: ", selection_runs(), "\n",
      "input$viewer_selection: ", format(input$viewer_selection), "\n",
      "input$viewer_selAround: ", substr(format(input$viewer_selAround), 1, 60)
    )
  })
}

shinyApp(ui, server)
