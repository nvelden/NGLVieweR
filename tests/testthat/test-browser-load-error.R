# Bug #8: when loading fails, Shiny gets a clear input$<id>_error, the
# structure inputs are cleared, nothing is shown and getStructure() is null.
# A load failure without network: file contents with a format NGL does not
# know ("xyz") make stage.loadFile() reject.

load_error_app <- function(env = parent.frame()) {
  make_app(c(
    "pdb <- file.path(fixture_dir, '1crn.pdb')",
    "pdb_text <- paste(readLines(pdb), collapse = '\\n')",
    "ui <- fluidPage(textInput('choice', 'choice', 'good'), NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    w <- switch(input$choice,",
    "      good  = NGLVieweR(pdb),",
    "      bad   = NGLVieweR(pdb_text, format = 'xyz'),",
    "      mixed = NGLVieweR(pdb) %>% addStructure(pdb_text, format = 'xyz'),",
    "      twobad = NGLVieweR(pdb_text, format = 'xyz') %>% addStructure(pdb_text, format = 'abc'),",
    "      badrep = NGLVieweR(pdb) %>% addRepresentation('nosuchrepresentation'),",
    "      empty = NGLVieweR(file.path(fixture_dir, 'broken.pdb')))",
    "    w %>% addRepresentation('cartoon')",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# Renders `choice` and waits until the widget reported the result: either
# _error is set, or it is NULL again and _sequence has arrived.
render_choice <- function(app, choice, expect_error) {
  app$set_inputs(choice = choice, wait_ = FALSE)
  cond <- if (expect_error) {
    "Shiny.shinyapp.$inputValues['viewer_error'] != null"
  } else {
    "Shiny.shinyapp.$inputValues['viewer_error'] == null &&
     Shiny.shinyapp.$inputValues['viewer_sequence'] != null"
  }
  app$wait_for_js(cond, timeout = 20000)
}

nothing_shown <- function(app) {
  widget_js(app, "stage.compList.length === 0 && w.getStructure() === null")
}

# Console errors that are not NGLVieweR's own load-error messages.
unexpected_errors <- function(app) {
  e <- console_errors(app)
  e[!grepl("^NGLVieweR: could not load", e)]
}

test_that("a structure NGL cannot load sets _error and clears the inputs", {
  skip_if_no_browser()
  app <- start_app(load_error_app())
  expect_length(unlist(app$get_value(input = "viewer_sequence")), 46)

  render_choice(app, "bad", expect_error = TRUE)
  expect_match(app$get_value(input = "viewer_error"), "structure 1")
  expect_null(app$get_value(input = "viewer_sequence"))
  expect_null(app$get_value(input = "viewer_resno"))
  expect_null(app$get_value(input = "viewer_chainname"))
  expect_null(app$get_value(input = "viewer_PDB"))
  expect_true(nothing_shown(app))
  expect_equal(unexpected_errors(app), character())
})

test_that("a successful render after a failure resets _error", {
  skip_if_no_browser()
  app <- start_app(load_error_app())
  render_choice(app, "bad", expect_error = TRUE)
  render_choice(app, "good", expect_error = FALSE)
  expect_null(app$get_value(input = "viewer_error"))
  expect_length(unlist(app$get_value(input = "viewer_sequence")), 46)
  expect_equal(widget_js(app, "w.getStructure().length"), 1)
})

test_that("one failing structure of several: nothing shown, error names it", {
  skip_if_no_browser()
  app <- start_app(load_error_app())
  render_choice(app, "mixed", expect_error = TRUE)
  expect_match(app$get_value(input = "viewer_error"), "structure 2")
  expect_null(app$get_value(input = "viewer_sequence"))
  expect_true(nothing_shown(app))
  expect_equal(unexpected_errors(app), character())
})

test_that("a structure without atoms is reported as an error", {
  skip_if_no_browser()
  app <- start_app(load_error_app())
  render_choice(app, "empty", expect_error = TRUE)
  expect_match(app$get_value(input = "viewer_error"), "structure 1 .*no atoms")
  expect_null(app$get_value(input = "viewer_sequence"))
  expect_true(nothing_shown(app))
})

test_that("every failing structure is named", {
  skip_if_no_browser()
  app <- start_app(load_error_app())
  render_choice(app, "twobad", expect_error = TRUE)
  err <- app$get_value(input = "viewer_error")
  expect_match(err, "structure 1")
  expect_match(err, "structure 2")
})

test_that("an error after loading is reported but keeps the structure", {
  skip_if_no_browser()
  app <- start_app(load_error_app())
  render_choice(app, "badrep", expect_error = TRUE)
  expect_match(app$get_value(input = "viewer_error"), "error while displaying")
  expect_equal(widget_js(app, "stage.compList.length"), 1)
})

test_that("_error is sent as an event, so the same message triggers again", {
  skip_if_no_browser()
  app <- start_app(load_error_app())
  app$run_js("window.__errorOpts = [];
    var orig = Shiny.onInputChange;
    Shiny.onInputChange = function(name, value, opts) {
      if (name === 'viewer_error' && value) window.__errorOpts.push(opts && opts.priority);
      return orig.apply(this, arguments);
    };")
  render_choice(app, "bad", expect_error = TRUE)
  expect_equal(unlist(app$get_js("window.__errorOpts")), "event")
})
