# Bug #21: updateColor()/updateVisibility()/updateRepresentation()/
# updateStage() set input$<id>_rendering to FALSE right after their own work,
# even while NGL is still busy (a rebuild, a snapshot). And the NGL task
# counter handler read the change (+1/-1) as the count, so FALSE was sent
# when one of two overlapping tasks finished.

rendering_app <- function(env = parent.frame()) {
  make_app(c(
    "ui <- fluidPage(",
    "  actionButton('snap', 'snap'),",
    "  actionButton('color', 'color'),",
    "  actionButton('visibility', 'visibility'),",
    "  actionButton('representation', 'representation'),",
    "  actionButton('stage', 'stage'),",
    "  actionButton('rebuild', 'rebuild'),",
    "  NGLVieweROutput('viewer')",
    ")",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    NGLVieweR(file.path(fixture_dir, '1crn.pdb')) %>%",
    "      addRepresentation('cartoon', param = list(name = 'cartoon')) %>%",
    "      addRepresentation('surface', param = list(name = 'surf', opacity = 0.4))",
    "  })",
    "  proxy <- NGLVieweR_proxy('viewer')",
    "  observeEvent(input$snap, snapShot(proxy, 'shot'))",
    "  observeEvent(input$color, updateColor(proxy, 'cartoon', 'red'))",
    "  observeEvent(input$visibility, updateVisibility(proxy, 'cartoon', FALSE))",
    "  observeEvent(input$representation,",
    "    updateRepresentation(proxy, 'cartoon', param = list(opacity = 0.5)))",
    "  observeEvent(input$stage, updateStage(proxy, param = list(backgroundColor = 'grey')))",
    "  observeEvent(input$rebuild,",
    "    updateRepresentation(proxy, 'surf', param = list(probeRadius = input$rebuild + 1.1)))",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# Records every `_rendering` value with NGL's task count at that moment, and
# snapshot downloads. With `slow_snapshot`, stage.makeImage() is a stub that
# resolves after 500 ms outside NGL's task counter, so only the snapshot
# handler keeps `_rendering` TRUE.
record_rendering <- function(app, slow_snapshot = FALSE) {
  app$wait_for_js("HTMLWidgets.find('#viewer').getStage().tasks.count === 0", timeout = 30000)
  app$run_js(sprintf("
    window.__events = [];
    var stage = HTMLWidgets.find('#viewer').getStage();
    if (%s) {
      stage.makeImage = function() {
        return new Promise(function(resolve) {
          setTimeout(function() { resolve(new Blob(['png'])); }, 500);
        });
      };
    }
    var orig = Shiny.onInputChange;
    Shiny.onInputChange = function(name, value) {
      if (name === 'viewer_rendering') {
        window.__events.push('rendering ' + value + ' (tasks ' + stage.tasks.count + ')');
      }
      return orig.apply(this, arguments);
    };
    NGL.download = function(blob, name) { window.__events.push('download ' + name); };",
    tolower(slow_snapshot)))
}

events <- function(app) unlist(app$get_js("window.__events"))

# TRUE once NGL is idle and the last value sent is FALSE.
wait_rendering_done <- function(app, extra = "true") {
  app$wait_for_js(sprintf(
    "(function(){ var e = window.__events, stage = HTMLWidgets.find('#viewer').getStage();
       return stage.tasks.count === 0 && e.length > 0 &&
         e[e.length - 1].indexOf('rendering false') === 0 && (%s); })()", extra),
    timeout = 15000)
}

for (update in c("color", "visibility", "representation", "stage")) {
  test_that(sprintf("an update%s during a snapshot keeps _rendering TRUE until the download", update), {
    skip_if_no_browser()
    app <- start_app(rendering_app())
    record_rendering(app, slow_snapshot = TRUE)
    app$run_js(sprintf("$('#snap').click(); setTimeout(function() { $('#%s').click(); }, 100);", update))
    wait_rendering_done(app, "window.__events.indexOf('download shot') >= 0")
    e <- events(app)
    download_at <- match("download shot", e)
    expect_false(any(grepl("^rendering false", e[seq_len(download_at - 1)])), info = paste(e, collapse = "\n"))
    expect_match(e[length(e)], "^rendering false")
  })
}

test_that("a rebuild started by updateRepresentation keeps _rendering TRUE until it ends", {
  skip_if_no_browser()
  app <- start_app(rendering_app())
  record_rendering(app)
  app$click("rebuild", wait_ = FALSE)
  # The surface rebuild is one NGL task
  wait_rendering_done(app, "window.__events.some(function(x) { return / \\(tasks 1\\)$/.test(x); })")
  e <- events(app)
  expect_false(any(grepl("^rendering false \\(tasks [1-9]", e)), info = paste(e, collapse = "\n"))
  expect_equal(e[length(e)], "rendering false (tasks 0)")
})

test_that("updateColor() alone still ends with _rendering FALSE", {
  skip_if_no_browser()
  app <- start_app(rendering_app())
  record_rendering(app)
  app$click("color", wait_ = FALSE)
  wait_rendering_done(app)
  e <- events(app)
  expect_equal(e[1], "rendering true (tasks 0)")
  expect_equal(e[length(e)], "rendering false (tasks 0)")
  expect_equal(app$get_value(input = "viewer_rendering"), FALSE)
})

test_that("two overlapping NGL tasks: _rendering is FALSE only after both end", {
  skip_if_no_browser()
  app <- start_app(rendering_app())
  record_rendering(app)
  app$run_js("var t = HTMLWidgets.find('#viewer').getStage().tasks;
              t.increment(); t.increment(); t.decrement(); t.decrement();")
  e <- events(app)
  expect_equal(sum(grepl("^rendering false", e)), 1)
  expect_equal(e[length(e)], "rendering false (tasks 0)")
})

test_that("removing a representation while it builds does not leave _rendering TRUE", {
  skip_if_no_browser()
  app <- start_app(rendering_app())
  record_rendering(app)
  # NGL 2.5.0 keeps the running build's task on the stage counter when the
  # representation is disposed, so the count would never return to zero.
  open <- app$get_js("(function(){ var stage = HTMLWidgets.find('#viewer').getStage();
    stage.getRepresentationsByName('surf').build();
    var open = stage.tasks.count;
    stage.removeAllComponents();
    return open; })()")
  expect_gt(open, 0)
  wait_rendering_done(app)
  expect_equal(widget_js(app, "stage.tasks.count"), 0)
  expect_equal(app$get_value(input = "viewer_rendering"), FALSE)
})

test_that("a representation whose build failed stops counting once removed", {
  skip_if_no_browser()
  app <- start_app(rendering_app())
  record_rendering(app)
  # An invalid parameter makes NGL's build throw; NGL never closes its task
  open <- app$get_js("(function(){ var stage = HTMLWidgets.find('#viewer').getStage();
    try { stage.getRepresentationsByName('cartoon').setParameters({subdiv: -1}); } catch (e) {}
    return stage.tasks.count; })()")
  expect_equal(open, 1)
  app$run_js("HTMLWidgets.find('#viewer').getStage().removeAllComponents();")
  wait_rendering_done(app)
  expect_equal(widget_js(app, "stage.tasks.count"), 0)
})
