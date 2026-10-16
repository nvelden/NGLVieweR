# Characterisation tests: current, correct browser behaviour of the widget.

basic_app <- function(env = parent.frame()) {
  make_app(c(
    "ui <- fluidPage(NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    NGLVieweR(file.path(fixture_dir, '1crn.pdb')) %>%",
    "      addRepresentation('cartoon', param = list(name = 'cartoon'))",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

test_that("widget renders the 1crn fixture and sends structure data to Shiny", {
  skip_if_no_browser()
  app <- start_app(basic_app())
  app$wait_for_value(input = "viewer_PDB", ignore = list(NULL))

  # The app must run the bundled NGL from the working tree.
  expect_equal(app$get_js("NGL.Version"), "2.4.0")
  expect_equal(widget_js(app, "w.getStructure().length"), 1)
  expect_equal(widget_js(app, "w.getStructure()[0].structure.atomCount"), 327)
  expect_equal(widget_js(app, "stage.getRepresentationsByName('cartoon').list.length"), 1)

  # One structure: one element per residue.
  seq <- app$get_value(input = "viewer_sequence")
  expect_equal(paste(unlist(seq), collapse = ""),
               "TTCCPSIVARSNFNVCRLPGTPEAICATYTGCIIIPGATCPGDYAN")
  expect_equal(as.integer(unlist(app$get_value(input = "viewer_resno"))), 1:46)
  expect_equal(unique(unlist(app$get_value(input = "viewer_chainname"))), "A")
  pdb <- unlist(app$get_value(input = "viewer_PDB"))
  expect_length(pdb, 1)
  expect_match(pdb, "ATOM ")

  expect_equal(console_errors(app), character())
})

test_that("a click on an atom sets _selection and _selAround", {
  skip_if_no_browser()
  app <- start_app(basic_app())

  # Dispatch the clicked signal with a picking proxy for atom 0 (THR 1 N),
  # the same object NGL passes when the user clicks that atom.
  app$run_js("
    var w = HTMLWidgets.find('#viewer');
    var comp = w.getStructure()[0];
    var atom = comp.structure.getAtomProxy(0);
    w.getStage().signals.clicked.dispatch({
      getLabel: function() { return 'test-label'; },
      atom: atom,
      component: comp
    });
  ")
  app$wait_for_value(input = "viewer_selAround", ignore = list(NULL))
  expect_equal(app$get_value(input = "viewer_selection"), "test-label")
  sel_around <- app$get_value(input = "viewer_selAround")
  expect_type(sel_around, "character")
  expect_match(sel_around, "@")
  expect_equal(console_errors(app), character())
})
