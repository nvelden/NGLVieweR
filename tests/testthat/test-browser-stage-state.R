# Bug #3: stage-wide state (spin, rock, stageParameters) must follow the
# options of the latest render, because the stage survives re-renders.

stage_state_app <- function(env = parent.frame()) {
  make_app(c(
    "ui <- fluidPage(",
    "  checkboxInput('spin', 'spin', FALSE),",
    "  checkboxInput('rock', 'rock', FALSE),",
    "  checkboxInput('white', 'white', FALSE),",
    "  checkboxInput('proxySpin', 'proxySpin', FALSE),",
    "  checkboxInput('proxyRock', 'proxyRock', FALSE),",
    "  NGLVieweROutput('viewer')",
    ")",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    w <- NGLVieweR(file.path(fixture_dir, '1crn.pdb')) %>%",
    "      addRepresentation('cartoon') %>%",
    "      setSpin(input$spin) %>%",
    "      setRock(input$rock)",
    "    if (input$white) w <- w %>% stageParameters(backgroundColor = 'white')",
    "    w",
    "  })",
    "  observeEvent(input$proxySpin, updateSpin(NGLVieweR_proxy('viewer'), input$proxySpin), ignoreInit = TRUE)",
    "  observeEvent(input$proxyRock, updateRock(NGLVieweR_proxy('viewer'), input$proxyRock), ignoreInit = TRUE)",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

spinning <- function(app) widget_js(app, "!stage.spinAnimation.paused")
rocking <- function(app) widget_js(app, "!stage.rockAnimation.paused")

test_that("spin switches off when a re-render sets spin = FALSE", {
  skip_if_no_browser()
  app <- start_app(stage_state_app())
  expect_false(spinning(app))
  rerender(app, spin = TRUE)
  expect_true(spinning(app))
  rerender(app, spin = FALSE)
  expect_false(spinning(app))
  expect_false(rocking(app))
})

test_that("rock switches off when a re-render sets rock = FALSE", {
  skip_if_no_browser()
  app <- start_app(stage_state_app())
  rerender(app, rock = TRUE)
  expect_true(rocking(app))
  rerender(app, rock = FALSE)
  expect_false(rocking(app))
  expect_false(spinning(app))
})

test_that("spin and rock both TRUE: spin wins", {
  skip_if_no_browser()
  app <- start_app(stage_state_app())
  rerender(app, spin = TRUE, rock = TRUE)
  expect_true(spinning(app))
  expect_false(rocking(app))
  rerender(app, spin = FALSE, rock = FALSE)
  expect_false(spinning(app))
  expect_false(rocking(app))
})

test_that("updateSpin() and updateRock() still work after a re-render", {
  skip_if_no_browser()
  app <- start_app(stage_state_app())
  rerender(app, spin = TRUE)
  rerender(app, spin = FALSE)
  app$set_inputs(proxySpin = TRUE)
  app$wait_for_js("!HTMLWidgets.find('#viewer').getStage().spinAnimation.paused")
  expect_true(spinning(app))
  app$set_inputs(proxyRock = TRUE)
  app$wait_for_js("!HTMLWidgets.find('#viewer').getStage().rockAnimation.paused")
  expect_true(rocking(app))
  expect_false(spinning(app))
})

test_that("stageParameters() removed in a later render go back to the defaults", {
  skip_if_no_browser()
  app <- start_app(stage_state_app())
  default_bg <- widget_js(app, "stage.parameters.backgroundColor")
  rerender(app, white = TRUE)
  expect_equal(widget_js(app, "stage.parameters.backgroundColor"), "white")
  rerender(app, white = FALSE)
  expect_equal(widget_js(app, "stage.parameters.backgroundColor"), default_bg)
  expect_equal(console_errors(app), character())
})

test_that("stage parameters that no render set are left alone on re-render", {
  skip_if_no_browser()
  app <- start_app(stage_state_app())
  # Changed outside renderNGLVieweR() (as updateStage() or custom JS would).
  app$run_js("HTMLWidgets.find('#viewer').getStage().setParameters({zoomSpeed: 7, mousePreset: 'pymol'});")
  rerender(app, white = TRUE)
  rerender(app, white = FALSE)
  expect_equal(widget_js(app, "stage.parameters.zoomSpeed"), 7)
  expect_equal(widget_js(app, "stage.parameters.mousePreset"), "pymol")
})
