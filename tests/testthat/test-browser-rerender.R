# Bug #2: renderValue() must not add a new set of event listeners every time
# renderNGLVieweR() re-runs, and the click handler must use the options of
# the latest render.

rerender_app <- function(env = parent.frame()) {
  make_app(c(
    "ui <- fluidPage(",
    "  selectInput('rep', 'rep', c('cartoon', 'ball+stick', 'spacefill')),",
    "  numericInput('proximity', 'proximity', 3),",
    "  NGLVieweROutput('viewer')",
    ")",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    NGLVieweR(file.path(fixture_dir, '1crn.pdb')) %>%",
    "      addRepresentation(input$rep, param = list(name = 'rep')) %>%",
    "      selectionParameters(proximity = input$proximity, level = 'residue')",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# Changes an input that renderNGLVieweR() depends on and waits until the
# widget has loaded the structure of the new render.
rerender <- function(app, ...) {
  app$run_js("HTMLWidgets.find('#viewer').getStructure()[0].__oldRender = true;")
  app$set_inputs(..., wait_ = FALSE)
  app$wait_for_js(
    "(function(){ var s = HTMLWidgets.find('#viewer').getStructure();
       return !!(s && s.length > 0 && !s[0].__oldRender && s[0].reprList.length > 0); })()",
    timeout = 30000)
}

# Records every value the widget sends for the given inputs from now on.
record_sends <- function(app, names) {
  app$run_js(sprintf("
    window.__sent = {};
    var names = %s;
    if (!window.__origOnInputChange) window.__origOnInputChange = Shiny.onInputChange;
    Shiny.onInputChange = function(name, value) {
      if (names.indexOf(name) >= 0) (window.__sent[name] = window.__sent[name] || []).push(value);
      return window.__origOnInputChange.apply(this, arguments);
    };", paste0("['", paste(names, collapse = "','"), "']")))
}

# Dispatches the clicked signal for atom 0 of the first structure, the same
# way NGL does when the user clicks that atom.
click_atom0 <- function(app) {
  app$run_js("
    var w = HTMLWidgets.find('#viewer');
    var comp = w.getStructure()[0];
    w.getStage().signals.clicked.dispatch({
      getLabel: function() { return 'atom0'; },
      atom: comp.structure.getAtomProxy(0),
      component: comp
    });")
}

test_that("re-rendering does not add listeners", {
  skip_if_no_browser()
  app <- start_app(rerender_app())
  expect_equal(widget_js(app, "stage.signals.clicked.getNumListeners()"), 1)
  expect_equal(widget_js(app, "stage.tasks.signals.countChanged.getNumListeners()"), 1)

  for (rep in c("ball+stick", "spacefill", "cartoon")) rerender(app, rep = rep)

  expect_equal(widget_js(app, "stage.signals.clicked.getNumListeners()"), 1)
  expect_equal(widget_js(app, "stage.tasks.signals.countChanged.getNumListeners()"), 1)

  # The single countChanged handler still reports when rendering is done.
  app$wait_for_js("Shiny.shinyapp.$inputValues['viewer_rendering'] === false", timeout = 30000)
  expect_false(app$get_value(input = "viewer_rendering"))
})

test_that("after re-renders one click sends _selection and _selAround once", {
  skip_if_no_browser()
  app <- start_app(rerender_app())
  for (rep in c("ball+stick", "spacefill", "cartoon")) rerender(app, rep = rep)

  record_sends(app, c("viewer_selection", "viewer_selAround"))
  click_atom0(app)
  sent <- app$get_js("window.__sent")
  expect_length(sent$viewer_selection, 1)
  expect_length(sent$viewer_selAround, 1)
})

test_that("the click handler uses selectionParameters() of the latest render", {
  skip_if_no_browser()
  app <- start_app(rerender_app())
  rerender(app, proximity = 1)
  rerender(app, proximity = 8)

  # _selAround for atom 0 (THR 1) computed directly with proximity 8.
  expected <- widget_js(app, "(function(){
    var s = w.getStructure()[0].structure;
    var resi = s.getAtomProxy(0).qualifiedName().split(']').pop().split('.')[0];
    var set = s.getAtomSetWithinSelection(new NGL.Selection(resi), 8);
    return s.getAtomSetWithinGroup(set).toSeleString();
  })()")

  record_sends(app, "viewer_selAround")
  click_atom0(app)
  # Every value computed for this click, not only the last one Shiny keeps.
  expect_equal(unlist(app$get_js("window.__sent.viewer_selAround")), expected)
  app$wait_for_value(input = "viewer_selAround", ignore = list(NULL))
  expect_equal(app$get_value(input = "viewer_selAround"), expected)
})

test_that("a window resize calls handleResize once after re-renders", {
  skip_if_no_browser()
  app <- start_app(rerender_app())
  for (rep in c("ball+stick", "spacefill")) rerender(app, rep = rep)

  app$run_js("
    var stage = HTMLWidgets.find('#viewer').getStage();
    window.__resizeCalls = 0;
    var orig = stage.handleResize;
    stage.handleResize = function() { window.__resizeCalls++; return orig.apply(this, arguments); };")
  app$set_window_size(800, 700)
  # Shiny calls resize() after a 500 ms debounce; count every call, not
  # only the immediate ones.
  Sys.sleep(2)
  expect_equal(app$get_js("window.__resizeCalls"), 1)
  # The canvas follows the new container width.
  expect_equal(widget_js(app, "stage.viewer.width === w.getStage().viewer.container.clientWidth"), TRUE)
})

test_that("the widget's resize() method resizes the stage", {
  skip_if_no_browser()
  app <- start_app(rerender_app())
  app$run_js("
    var w = HTMLWidgets.find('#viewer');
    var stage = w.getStage();
    window.__resizeCalls = 0;
    var orig = stage.handleResize;
    stage.handleResize = function() { window.__resizeCalls++; return orig.apply(this, arguments); };
    w.resize(500, 300);")
  expect_equal(app$get_js("window.__resizeCalls"), 1)
  expect_equal(console_errors(app), character())
})
