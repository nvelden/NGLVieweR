pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #10: snapShot() resets input$<id>_rendering too early.
# Launch from the project root:
#   shiny::runApp("dev/repro/10-snapshot", launch.browser = TRUE)

pdb <- normalizePath("../../../tests/testthat/fixtures/1crn.pdb")

# Logs, in the browser, every _rendering value the widget sends and the
# moment the PNG download starts, with milliseconds since the click.
log_js <- HTML("
$(document).on('shiny:connected', function() {
  window.snapLog = [];
  window.snapStart = null;
  function log(what) {
    if (window.snapStart === null) return;
    window.snapLog.push(Math.round(performance.now() - window.snapStart) + ' ms  ' + what);
    Shiny.setInputValue('snaplog', window.snapLog.slice());
  }
  var orig = Shiny.onInputChange;
  Shiny.onInputChange = function(name, value) {
    if (name === 'viewer_rendering') log('_rendering = ' + value);
    return orig.apply(this, arguments);
  };
  Shiny.setInputValue = Shiny.onInputChange;
  var origDownload = NGL.download;
  NGL.download = function() {
    log('PNG ready, download starts');
    if (!document.getElementById('save').checked) return;  // skip the actual file save
    return origDownload.apply(this, arguments);
  };
  $(document).on('click', '#snap', function() {
    window.snapLog = [];
    window.snapStart = performance.now();
    log('button clicked');
  });
});
")

ui <- fluidPage(
  tags$head(tags$script(log_js)),
  titlePanel("Bug #10: snapShot() resets _rendering too early"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Press 'Snapshot'. The log shows the order of events. ",
           "'_rendering = false' appears BEFORE 'PNG ready'. An app that shows a spinner while ",
           "input$viewer_rendering is TRUE hides it before the image exists."),
    tags$p("Correct order: _rendering = true, PNG ready, _rendering = false.")
  ),
  fluidRow(
    column(4,
      actionButton("snap", "Snapshot (factor 4, antialias)"),
      checkboxInput("save", "Actually save the PNG", FALSE),
      h4("Spinner driven by input$viewer_rendering"),
      uiOutput("spinner"),
      h4("Event log"),
      verbatimTextOutput("log")
    ),
    column(8, NGLVieweROutput("viewer", height = "450px"))
  )
)

server <- function(input, output, session) {
  output$viewer <- renderNGLVieweR({
    NGLVieweR(pdb) %>% addRepresentation("ball+stick")
  })
  observeEvent(input$snap, {
    NGLVieweR_proxy("viewer") %>%
      snapShot("snapshot", param = list(factor = 4, antialias = TRUE, trim = TRUE))
  })
  output$spinner <- renderUI({
    if (isTRUE(input$viewer_rendering)) tags$b(style = "color: darkorange", "busy...")
    else tags$span("idle")
  })
  output$log <- renderText(paste(unlist(input$snaplog), collapse = "\n"))
}

shinyApp(ui, server)
