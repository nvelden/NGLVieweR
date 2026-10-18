pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #21: updateColor()/updateVisibility()/updateRepresentation()/
# updateStage() set input$<id>_rendering to FALSE 10 ms after they start,
# regardless of NGL work that is still running (a snapshot, a rebuild).
# Launch from the project root:
#   shiny::runApp("dev/repro/21-update-rendering", launch.browser = TRUE)

pdb <- normalizePath("../../../tests/testthat/fixtures/1crn.pdb")

# Logs, in the browser, every _rendering value the widget sends, NGL's task
# count, and the moment a snapshot PNG is ready, with ms since the click.
# The debug panel shows "_rendering = false while NGL is busy" as a count.
log_js <- HTML("
$(document).on('shiny:connected', function() {
  window.rLog = [];
  window.rStart = null;
  window.rWrong = 0;
  window.rTasks = 0;
  window.rSnapPending = 0;
  function send() {
    Shiny.setInputValue('rlog', window.rLog.slice());
    Shiny.setInputValue('rwrong', window.rWrong);
  }
  function log(what) {
    if (window.rStart === null) return;
    window.rLog.push(Math.round(performance.now() - window.rStart) + ' ms  ' + what);
  }
  var orig = Shiny.onInputChange;
  Shiny.onInputChange = function(name, value) {
    if (name === 'viewer_rendering') {
      // Read the count from the stage: NGLVieweR's own listener runs before ours
      var w = HTMLWidgets.find('#viewer');
      var stage = w && w.getStage && w.getStage();
      var tasks = stage ? stage.tasks.count : 0;
      var busy = tasks > 0 || window.rSnapPending > 0;
      log('_rendering = ' + value + (value === false && busy ? '   <-- WRONG: NGL still busy (tasks ' +
          tasks + ', snapshots ' + window.rSnapPending + ')' : ''));
      if (value === false && busy && window.rStart !== null) window.rWrong++;
      send();
    }
    return orig.apply(this, arguments);
  };
  Shiny.setInputValue = Shiny.onInputChange;
  var origDownload = NGL.download;
  NGL.download = function() {
    window.rSnapPending--;
    log('PNG ready (download skipped)');
    send();
  };
  // Watch NGL's task counter once the stage exists
  var timer = setInterval(function() {
    var w = HTMLWidgets.find('#viewer');
    var stage = w && w.getStage && w.getStage();
    if (!stage) return;
    clearInterval(timer);
    stage.tasks.signals.countChanged.add(function(delta, count) {
      window.rTasks = count;
      log('NGL tasks = ' + count + ' (' + (delta > 0 ? '+' : '') + delta + ')');
    });
  }, 100);
  $(document).on('click', '.run', function() {
    window.rLog = [];
    window.rWrong = 0;
    window.rStart = performance.now();
    if (this.id === 'snapcolor') window.rSnapPending++;
    log('button clicked: ' + this.id);
    send();
  });
});
")

ui <- fluidPage(
  tags$head(tags$script(log_js)),
  titlePanel("Bug #21: update functions reset _rendering too early"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Each button runs one case. The log lists every _rendering value with the time ",
           "since the click, and NGL's own task count."),
    tags$ul(
      tags$li(tags$b("Snapshot + updateColor: "), "a slow snapshot, and updateColor() right after. ",
              "'_rendering = false' appears BEFORE 'PNG ready' (undoes the #10 fix)."),
      tags$li(tags$b("updateRepresentation (rebuild): "), "changes the surface probe radius, so NGL ",
              "rebuilds the surface. '_rendering = false' appears while 'NGL tasks = 1'."),
      tags$li(tags$b("updateColor only: "), "control case; nothing slow runs, so no WRONG line.")
    ),
    tags$p("Correct: no line marked WRONG, and the spinner stays 'busy' until the last NGL work ends.")
  ),
  fluidRow(
    column(5,
      actionButton("snapcolor", "Snapshot + updateColor", class = "run"),
      actionButton("rebuild", "updateRepresentation (rebuild)", class = "run"),
      actionButton("color", "updateColor only", class = "run"),
      h4("Debug panel"),
      uiOutput("debug"),
      h4("Spinner driven by input$viewer_rendering"),
      uiOutput("spinner"),
      h4("Event log"),
      verbatimTextOutput("log")
    ),
    column(7, NGLVieweROutput("viewer", height = "450px"))
  )
)

server <- function(input, output, session) {
  output$viewer <- renderNGLVieweR({
    NGLVieweR(pdb) %>%
      addRepresentation("cartoon", param = list(name = "cartoon", color = "residueindex")) %>%
      addRepresentation("surface", param = list(name = "surf", opacity = 0.4, color = "white"))
  })
  colors <- c("red", "blue", "green", "orange")
  observeEvent(input$snapcolor, {
    NGLVieweR_proxy("viewer") %>%
      snapShot("snapshot", param = list(factor = 4, antialias = TRUE, trim = TRUE))
    NGLVieweR_proxy("viewer") %>% updateColor("cartoon", sample(colors, 1))
  })
  observeEvent(input$rebuild, {
    NGLVieweR_proxy("viewer") %>%
      updateRepresentation("surf", param = list(probeRadius = round(runif(1, 1.2, 2.5), 2)))
  })
  observeEvent(input$color, {
    NGLVieweR_proxy("viewer") %>% updateColor("cartoon", sample(colors, 1))
  })
  output$debug <- renderUI({
    n <- input$rwrong %||% 0
    tags$p(style = if (n > 0) "color: firebrick; font-weight: bold",
           sprintf("_rendering = FALSE while NGL was busy: %d time(s) in the last run", n))
  })
  output$spinner <- renderUI({
    if (isTRUE(input$viewer_rendering)) tags$b(style = "color: darkorange", "busy...")
    else tags$span("idle")
  })
  output$log <- renderText(paste(unlist(input$rlog), collapse = "\n"))
}

shinyApp(ui, server)
