# Bug #10: snapShot() must keep input$<id>_rendering TRUE until the PNG has
# been made and handed to NGL.download(), and reset it when that fails.
# stage.makeImage() is replaced by a slow (or failing) stub and NGL.download()
# by a recorder, so the order of events is deterministic.

snapshot_app <- function(env = parent.frame()) {
  make_app(c(
    "ui <- fluidPage(actionButton('snap', 'snap'), NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    NGLVieweR(file.path(fixture_dir, '1crn.pdb')) %>% addRepresentation('cartoon')",
    "  })",
    "  observeEvent(input$snap, snapShot(NGLVieweR_proxy('viewer'), 'shot'))",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# Records `_rendering` values sent by the snapshot handler and the download,
# in order. `fail` makes the stubbed makeImage() reject.
record_snapshot <- function(app, fail = FALSE) {
  app$run_js(sprintf("
    window.__events = [];
    var stage = HTMLWidgets.find('#viewer').getStage();
    // Only the snapshot handler's own _rendering values: NGL's task counter
    // is silenced by keeping makeImage outside stage.tasks.
    stage.makeImage = function() {
      return new Promise(function(resolve, reject) {
        setTimeout(function() {
          %s
        }, 500);
      });
    };
    var orig = Shiny.onInputChange;
    Shiny.onInputChange = function(name, value) {
      if (name === 'viewer_rendering') window.__events.push('rendering ' + value);
      return orig.apply(this, arguments);
    };
    NGL.download = function(blob, name) { window.__events.push('download ' + name); };",
    if (fail) "reject(new Error('no WebGL'));" else "resolve(new Blob(['png']));"))
}

test_that("_rendering stays TRUE until the image has been downloaded", {
  skip_if_no_browser()
  app <- start_app(snapshot_app())
  record_snapshot(app)
  app$click("snap", wait_ = FALSE)
  app$wait_for_js("window.__events.indexOf('rendering false') >= 0", timeout = 10000)
  expect_equal(unlist(app$get_js("window.__events")),
               c("rendering true", "download shot", "rendering false"))
})

test_that("with the real makeImage(), _rendering is FALSE only after the download", {
  skip_if_no_browser()
  app <- start_app(snapshot_app())
  # Record every _rendering value (including NGL's task counter) and the
  # download; keep the real stage.makeImage().
  app$run_js("
    window.__events = [];
    var orig = Shiny.onInputChange;
    Shiny.onInputChange = function(name, value) {
      if (name === 'viewer_rendering') window.__events.push('rendering ' + value);
      return orig.apply(this, arguments);
    };
    NGL.download = function(blob, name) { window.__events.push('download ' + name); };")
  app$click("snap", wait_ = FALSE)
  app$wait_for_js("window.__events.indexOf('download shot') >= 0 &&
                   window.__events[window.__events.length - 1] === 'rendering false'",
                  timeout = 10000)
  events <- unlist(app$get_js("window.__events"))
  download_at <- match("download shot", events)
  expect_false("rendering false" %in% events[seq_len(download_at - 1)])
  expect_equal(events[length(events)], "rendering false")
})

test_that("two overlapping snapshots: _rendering is FALSE only after both", {
  skip_if_no_browser()
  app <- start_app(snapshot_app())
  record_snapshot(app)
  app$run_js("$('#snap').click(); setTimeout(function() { $('#snap').click(); }, 200);")
  app$wait_for_js("window.__events.filter(function(e) { return e === 'download shot'; }).length === 2 &&
                   window.__events[window.__events.length - 1] === 'rendering false'",
                  timeout = 10000)
  events <- unlist(app$get_js("window.__events"))
  second_download <- max(which(events == "download shot"))
  expect_false("rendering false" %in% events[seq_len(second_download - 1)])
})

test_that("a failing snapshot resets _rendering and logs an error", {
  skip_if_no_browser()
  app <- start_app(snapshot_app())
  record_snapshot(app, fail = TRUE)
  app$click("snap", wait_ = FALSE)
  app$wait_for_js("window.__events.indexOf('rendering false') >= 0", timeout = 10000)
  expect_equal(unlist(app$get_js("window.__events")),
               c("rendering true", "rendering false"))
  errors <- character()
  for (i in 1:30) {
    errors <- console_errors(app)
    if (length(errors) > 0) break
    Sys.sleep(0.1)
  }
  expect_true(any(grepl("NGLVieweR: snapshot failed: no WebGL", errors)))
})
