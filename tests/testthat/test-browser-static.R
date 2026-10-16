# The widget outside Shiny (R Markdown, saved HTML): renders, registers no
# Shiny handlers, and resizes.

test_that("a saved (non-Shiny) widget renders and resizes", {
  skip_if_no_browser()
  skip_if_not_installed("htmlwidgets")
  file <- withr::local_tempfile(fileext = ".html")
  w <- NGLVieweR(fixture("1crn.pdb")) %>% addRepresentation("cartoon")
  htmlwidgets::saveWidget(w, file, selfcontained = FALSE)
  # The saved page must use the working-tree widget JS, not an installed copy.
  saved_js <- list.files(dirname(file), "^NGLVieweR\\.js$", recursive = TRUE,
                         full.names = TRUE)
  saved_js <- saved_js[grepl("NGLVieweR-binding", saved_js)]
  expect_length(saved_js, 1)
  expect_identical(readLines(saved_js),
                   readLines(file.path(pkg_root(), "inst", "htmlwidgets", "NGLVieweR.js")))

  b <- chromote::ChromoteSession$new()
  withr::defer(b$close())
  b$Page$navigate(paste0("file://", normalizePath(file)), wait_ = FALSE)
  b$Page$loadEventFired()
  js <- function(expr) {
    b$Runtime$evaluate(expr, returnByValue = TRUE, awaitPromise = TRUE)$result$value
  }
  ready <- "(function(){ var w = HTMLWidgets.find('.NGLVieweR');
              return !!(w && w.getStructure() && w.getStructure().length > 0); })()"
  for (i in 1:100) if (isTRUE(js(ready))) break else Sys.sleep(0.1)
  expect_true(js(ready))

  expect_equal(js("HTMLWidgets.find('.NGLVieweR').getStructure()[0].structure.atomCount"), 327)
  # No Shiny: the Shiny-only handlers are not registered.
  expect_equal(js("HTMLWidgets.find('.NGLVieweR').getStage().signals.clicked.getNumListeners()"), 0)

  js("(function(){
    var stage = HTMLWidgets.find('.NGLVieweR').getStage();
    window.__resizeCalls = 0; var orig = stage.handleResize;
    stage.handleResize = function() { window.__resizeCalls++; return orig.apply(this, arguments); };
    })()")
  # A real viewport change: htmlwidgets calls resize() once.
  b$Emulation$setDeviceMetricsOverride(width = 700, height = 500,
                                       deviceScaleFactor = 1, mobile = FALSE)
  Sys.sleep(1)
  expect_equal(js("window.__resizeCalls"), 1)
  expect_true(js("(function(){ var v = HTMLWidgets.find('.NGLVieweR').getStage().viewer;
                   return v.width === v.container.clientWidth; })()"))
})
