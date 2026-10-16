# Bug #5: updateFullscreen(fullscreen, element) must end in the requested
# state instead of toggling. Browsers only allow fullscreen after a real
# user gesture, so these tests replace stage.toggleFullscreen with a spy
# and fake document.fullscreenElement.

fullscreen_app <- function(env = parent.frame()) {
  make_app(c(
    "ui <- fluidPage(textInput('cmd', 'cmd'), NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    NGLVieweR(file.path(fixture_dir, '1crn.pdb')) %>% addRepresentation('cartoon')",
    "  })",
    "  observeEvent(input$cmd, {",
    "    req(nzchar(input$cmd))",
    "    args <- strsplit(input$cmd, ' ')[[1]]",
    "    if (args[2] == 'page') updateFullscreen(NGLVieweR_proxy('viewer'), as.logical(args[1]))",
    "    else updateFullscreen(NGLVieweR_proxy('viewer'), as.logical(args[1]), element = args[2])",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# Installs the spy; `fullscreen` sets whether the page is currently fullscreen,
# `entered_by_ngl` whether this stage entered it (NGL then remembers the element).
spy_fullscreen <- function(app, fullscreen, entered_by_ngl = TRUE) {
  app$run_js(sprintf("
    var stage = HTMLWidgets.find('#viewer').getStage();
    window.__fsCalls = [];
    window.__fsElement = %s;
    if (window.__fsElement && %s) stage.lastFullscreenElement = document.body;
    Object.defineProperty(document, 'fullscreenElement',
      { get: function() { return window.__fsElement; }, configurable: true });
    stage.toggleFullscreen = function(el) {
      window.__fsCalls.push(el === document.body ? 'page' :
        (el === undefined || el === stage.viewer.container) ? 'viewer' : 'other');
    };", if (fullscreen) "document.body" else "null", tolower(entered_by_ngl)))
}

# Sends updateFullscreen(<fullscreen>, element = <element>) and returns the
# toggleFullscreen calls it caused.
send_fullscreen <- function(app, fullscreen, element) {
  cmd <- paste(fullscreen, element)
  app$set_inputs(cmd = cmd, wait_ = FALSE)
  Sys.sleep(0.5)
  unlist(app$get_js("window.__fsCalls"))
}

cases <- list(
  # currently fullscreen, request, element, expected toggleFullscreen calls
  list(FALSE, FALSE, "page",   character()),
  list(FALSE, TRUE,  "page",   "page"),
  list(FALSE, TRUE,  "viewer", "viewer"),
  list(TRUE,  TRUE,  "page",   character()),
  list(TRUE,  TRUE,  "viewer", character()),
  list(TRUE,  FALSE, "page",   "page"),
  # Leaving uses the element fullscreen was entered with (the page here).
  list(TRUE,  FALSE, "viewer", "page")
)

for (case in cases) {
  test_that(sprintf("fullscreen now %s, updateFullscreen(%s, element = '%s')",
                    case[[1]], case[[2]], case[[3]]), {
    skip_if_no_browser()
    app <- start_app(fullscreen_app())
    spy_fullscreen(app, case[[1]])
    calls <- send_fullscreen(app, case[[2]], case[[3]])
    expect_equal(as.character(calls), case[[4]])
    expect_equal(console_errors(app), character())
  })
}

test_that("leaving fullscreen that this stage did not enter uses the fullscreen element", {
  skip_if_no_browser()
  app <- start_app(fullscreen_app())
  spy_fullscreen(app, TRUE, entered_by_ngl = FALSE)
  calls <- send_fullscreen(app, FALSE, "page")
  expect_equal(as.character(calls), "page")
  expect_equal(console_errors(app), character())
})
