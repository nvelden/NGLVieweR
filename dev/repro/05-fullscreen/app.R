pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #5: updateFullscreen() ignores its argument.
# Launch from the project root:
#   shiny::runApp("dev/repro/05-fullscreen", launch.browser = TRUE)

pdb <- normalizePath("../../../tests/testthat/fixtures/1crn.pdb")

debug_js <- HTML("
$(document).on('shiny:connected', function() {
  window.fullscreenLog = [];
  function current() {
    var el = document.fullscreenElement || document.webkitFullscreenElement;
    return el ? el.tagName + (el.id ? '#' + el.id : '') + (el.className ? '.' + el.className.split(' ')[0] : '') : 'none';
  }
  document.addEventListener('fullscreenchange', function() {
    window.fullscreenLog.push(new Date().toLocaleTimeString() + '  ' + current());
  });
  setInterval(function() {
    Shiny.setInputValue('debug', { element: current(), log: window.fullscreenLog.slice(-6) });
  }, 300);
});
")

ui <- fluidPage(
  tags$head(tags$script(debug_js)),
  titlePanel("Bug #5: updateFullscreen() ignores its argument"),
  wellPanel(
    tags$b("What to look for"),
    tags$ol(
      tags$li("While NOT fullscreen, press 'updateFullscreen(FALSE)': the page goes fullscreen anyway."),
      tags$li("While fullscreen, press 'updateFullscreen(TRUE)': it leaves fullscreen. ",
              "(Use Esc to leave fullscreen if the buttons are not reachable.)"),
      tags$li("The fullscreen element is BODY (the whole page), not the viewer."),
      tags$li("After the fix: 'element = viewer' shows only the molecule fullscreen (leave with Esc).")
    ),
    tags$p("Correct behaviour: TRUE always ends in fullscreen, FALSE always ends not fullscreen; ",
           "pressing the same button twice changes nothing the second time.")
  ),
  fluidRow(
    column(4,
      actionButton("on", "updateFullscreen(TRUE)"),
      actionButton("off", "updateFullscreen(FALSE)"),
      actionButton("fsViewer", "updateFullscreen(TRUE, element = 'viewer')"),
      h4("Debug panel"),
      verbatimTextOutput("debug")
    ),
    column(8, NGLVieweROutput("viewer", height = "450px"))
  )
)

server <- function(input, output, session) {
  output$viewer <- renderNGLVieweR({
    NGLVieweR(pdb) %>% addRepresentation("cartoon")
  })
  observeEvent(input$on, NGLVieweR_proxy("viewer") %>% updateFullscreen(TRUE))
  observeEvent(input$off, NGLVieweR_proxy("viewer") %>% updateFullscreen(FALSE))
  observeEvent(input$fsViewer, NGLVieweR_proxy("viewer") %>% updateFullscreen(TRUE, element = "viewer"))

  output$debug <- renderText({
    d <- input$debug
    req(d)
    paste0("fullscreen element now: ", d$element, "\n\nchanges:\n",
           paste(unlist(d$log), collapse = "\n"))
  })
}

shinyApp(ui, server)
