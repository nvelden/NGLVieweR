# Bug #20 (GitHub #17): a PDB code is loaded as .pdb, and as .cif when that
# fails (RCSB has no .pdb file for large entries). The fallback is tested
# without network by serving the fixtures from Shiny and pointing `data` at a
# file that does not exist.

fallback_app <- function(env = parent.frame()) {
  make_app(c(
    "addResourcePath('fx', fixture_dir)",
    "code <- function(data, fallback = NULL) {",
    "  w <- NGLVieweR('1CRN')",
    "  w$x$structures[[1]]$data <- data",
    "  w$x$structures[[1]]$fallback <- fallback",
    "  w",
    "}",
    "ui <- fluidPage(textInput('choice', 'choice', 'direct'), NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    w <- switch(input$choice,",
    "      direct     = code('fx/1crn.pdb'),",
    "      fallback   = code('fx/missing.pdb', 'fx/1crn.pdb'),",
    "      bothfail   = code('fx/missing.pdb', 'fx/missing.cif'),",
    "      nofallback = code('fx/missing.pdb'))",
    "    w %>% addRepresentation('cartoon')",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

wait_for_error <- function(app) {
  app$wait_for_js("Shiny.shinyapp.$inputValues['viewer_error'] != null", timeout = 20000)
}

test_that("#20: a code that fails to load is loaded from the fallback", {
  skip_if_no_browser()
  app <- start_app(fallback_app())
  rerender(app, choice = "fallback")
  app$wait_for_value(input = "viewer_residues", ignore = list(NULL))
  expect_equal(nrow(app$get_value(input = "viewer_residues")), 46)
  expect_null(app$get_value(input = "viewer_error"))
  expect_equal(widget_js(app, "w.getStructure()[0].structure.atomCount"), 327)
})

test_that("#20: when the fallback also fails, the error names both", {
  skip_if_no_browser()
  app <- start_app(fallback_app())
  app$set_inputs(choice = "bothfail", wait_ = FALSE)
  wait_for_error(app)
  err <- app$get_value(input = "viewer_error")
  expect_match(err, "could not load structure 1", fixed = TRUE)
  expect_match(err, "fx/missing.pdb", fixed = TRUE)
  expect_match(err, "fx/missing.cif", fixed = TRUE)
  expect_true(widget_js(app, "stage.compList.length === 0 && w.getStructure() === null"))
})

test_that("#20: without a fallback only the given file is tried", {
  skip_if_no_browser()
  app <- start_app(fallback_app())
  app$set_inputs(choice = "nofallback", wait_ = FALSE)
  wait_for_error(app)
  err <- app$get_value(input = "viewer_error")
  expect_match(err, "fx/missing.pdb", fixed = TRUE)
  expect_false(grepl(" or ", err, fixed = TRUE))
})

# With network: the real entries from GitHub #17.
rcsb_app <- function(env = parent.frame()) {
  make_app(c(
    "ui <- fluidPage(textInput('choice', 'choice', '1CRN'), NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    w <- switch(input$choice,",
    "      '1CRN' = NGLVieweR('1CRN'),",
    "      '3J9M' = NGLVieweR('3J9M'),",
    "      '3J9M_cif' = NGLVieweR('3J9M', format = 'cif'))",
    "    w %>% addRepresentation('cartoon')",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

rcsb_requests <- function(app) {
  unlist(widget_js(app, "performance.getEntriesByType('resource')
    .map(function(e) { return e.name; }).filter(function(n) { return /rcsb\\.org/.test(n); })"))
}

test_that("#20: an entry with a legacy PDB file still loads only the .pdb", {
  skip_if_no_browser()
  skip_if_offline("files.rcsb.org")
  app <- start_app(rcsb_app())
  expect_equal(widget_js(app, "w.getStructure()[0].structure.atomCount"), 327)
  expect_equal(rcsb_requests(app), "https://files.rcsb.org/download/1CRN.pdb")
})

test_that("#20: an entry without a legacy PDB file (3J9M) loads", {
  skip_if_no_browser()
  skip_if_offline("files.rcsb.org")
  app <- start_app(rcsb_app())
  for (choice in c("3J9M", "3J9M_cif")) {
    rerender(app, choice = choice)
    expect_equal(widget_js(app, "w.getStructure()[0].structure.atomCount"), 158384,
                 label = choice)
    expect_null(app$get_value(input = "viewer_error"))
  }
  expect_true("https://files.rcsb.org/download/3J9M.cif" %in% rcsb_requests(app))
})
