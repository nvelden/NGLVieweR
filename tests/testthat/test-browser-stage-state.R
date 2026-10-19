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

# Bug #28: setFocus()/setQuality() must not override clipping, fog and quality
# set with stageParameters(). The stage applies stageParameters(), then
# setQuality()/setFocus() (setFocus() reads clipMode and clipScale), then puts
# back the clip/fog/quality keys that stageParameters() names.

focus_app <- function(env = parent.frame()) {
  make_app(c(
    "ui <- fluidPage(",
    "  selectInput('params', 'params', c('none', 'clip', 'fog', 'quality', 'fogFar', 'camera')),",
    "  checkboxInput('focus', 'focus', FALSE),",
    "  checkboxInput('quality', 'quality', FALSE),",
    "  NGLVieweROutput('viewer')",
    ")",
    "params <- list(none = list(), clip = list(clipNear = 45, clipFar = 90),",
    "  fog = list(fogNear = 0, fogFar = 30), quality = list(quality = 'low'),",
    "  fogFar = list(fogFar = 60), camera = list(clipMode = 'camera'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    w <- NGLVieweR(file.path(fixture_dir, '1crn.pdb')) %>%",
    "      addRepresentation('cartoon')",
    "    if (input$focus) w <- w %>% setFocus(50)",
    "    if (input$quality) w <- w %>% setQuality('high')",
    "    do.call(stageParameters, c(list(w), params[[input$params]]))",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

stage_values <- function(app) {
  widget_js(app, "(function(p){ return {clipNear: p.clipNear, clipFar: p.clipFar,
    fogNear: p.fogNear, fogFar: p.fogFar, quality: p.quality}; })(stage.parameters)")
}

ngl_defaults <- list(clipNear = 0, clipFar = 100, fogNear = 50, fogFar = 100,
                     quality = "medium")

test_that("a viewer without focus, quality or stage options has NGL's defaults", {
  skip_if_no_browser()
  app <- start_app(focus_app())
  expect_equal(stage_values(app), ngl_defaults)
})

test_that("stageParameters() clipping, fog and quality reach the stage", {
  skip_if_no_browser()
  app <- start_app(focus_app())
  rerender(app, params = "clip")
  expect_equal(stage_values(app)[c("clipNear", "clipFar")], list(clipNear = 45, clipFar = 90))
  rerender(app, params = "fog")
  expect_equal(stage_values(app)[c("fogNear", "fogFar")], list(fogNear = 0, fogFar = 30))
  # clip from the previous render is reset (#3)
  expect_equal(stage_values(app)[c("clipNear", "clipFar")], list(clipNear = 0, clipFar = 100))
  rerender(app, params = "quality")
  expect_equal(stage_values(app)$quality, "low")
  expect_equal(console_errors(app), character())
})

test_that("stageParameters() wins over setFocus() and setQuality()", {
  skip_if_no_browser()
  app <- start_app(focus_app())
  # setFocus(50) alone: clip 25/75, fog 50/100 (NGL, relative clip scale)
  rerender(app, focus = TRUE)
  expect_equal(stage_values(app)[c("clipNear", "clipFar", "fogNear", "fogFar")],
               list(clipNear = 25, clipFar = 75, fogNear = 50, fogFar = 100))
  # a named key wins, the other focus values stay
  rerender(app, params = "fogFar")
  expect_equal(stage_values(app)[c("clipNear", "clipFar", "fogNear", "fogFar")],
               list(clipNear = 25, clipFar = 75, fogNear = 50, fogFar = 60))
  rerender(app, quality = TRUE, params = "none")
  expect_equal(stage_values(app)$quality, "high")
  rerender(app, params = "quality")
  expect_equal(stage_values(app)$quality, "low")
})

test_that("focus and quality from a previous render go back to NGL's defaults", {
  skip_if_no_browser()
  app <- start_app(focus_app())
  rerender(app, focus = TRUE, quality = TRUE)
  expect_equal(stage_values(app)[c("clipNear", "quality")], list(clipNear = 25, quality = "high"))
  rerender(app, focus = FALSE, quality = FALSE)
  expect_equal(stage_values(app), ngl_defaults)
  expect_equal(console_errors(app), character())
})

test_that("setFocus() uses the clipMode from stageParameters() of the same render", {
  skip_if_no_browser()
  app <- start_app(focus_app())
  # NGL's setFocus() does nothing with clipMode "camera", so clipping stays at
  # the defaults. If setFocus() ran before stageParameters() it would still
  # see clipMode "scene" and set clip 25/75.
  rerender(app, focus = TRUE, params = "camera")
  expect_equal(widget_js(app, "stage.parameters.clipMode"), "camera")
  expect_equal(stage_values(app)[c("clipNear", "clipFar")], list(clipNear = 0, clipFar = 100))
})
