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

# Bug #29: the widget loads from every kind of saved output, after the
# dependencies copy only their own scripts.

# Opens a local HTML file in headless Chrome and returns the atom count of the
# first structure once it is loaded (NA if it never loads), plus console errors.
open_saved_page <- function(file) {
  b <- chromote::ChromoteSession$new()
  on.exit(b$close())
  errors <- character()
  b$Runtime$enable()
  b$Runtime$exceptionThrown(callback_ = function(x) {
    d <- x$exceptionDetails
    errors <<- c(errors, if (!is.null(d$exception$description)) d$exception$description else d$text)
  })
  b$Page$navigate(paste0("file://", normalizePath(file)), wait_ = FALSE)
  b$Page$loadEventFired()
  js <- function(expr) {
    b$Runtime$evaluate(expr, returnByValue = TRUE, awaitPromise = TRUE)$result$value
  }
  ready <- "(function(){ var w = window.HTMLWidgets && HTMLWidgets.find('.NGLVieweR');
              return !!(w && w.getStructure() && w.getStructure().length > 0); })()"
  for (i in 1:150) if (isTRUE(js(ready))) break else Sys.sleep(0.1)
  atoms <- if (isTRUE(js(ready))) {
    js("HTMLWidgets.find('.NGLVieweR').getStructure()[0].structure.atomCount")
  } else NA
  list(atoms = atoms, errors = errors,
       ngl = js("typeof NGL === 'object' ? NGL.Version : null"))
}

test_that("a self-contained saved widget renders", {
  skip_if_no_browser()
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  file <- withr::local_tempfile(fileext = ".html")
  w <- NGLVieweR(fixture("1crn.pdb")) %>% addRepresentation("cartoon")
  htmlwidgets::saveWidget(w, file, selfcontained = TRUE)
  page <- open_saved_page(file)
  expect_equal(page$atoms, 327)
  expect_equal(page$ngl, "2.5.0")
  expect_equal(page$errors, character())
})

test_that("a saved widget with a lib folder renders, also after moving it", {
  skip_if_no_browser()
  dir <- withr::local_tempdir()
  w <- NGLVieweR(fixture("1crn.pdb")) %>% addRepresentation("cartoon")
  htmlwidgets::saveWidget(w, file.path(dir, "w.html"), selfcontained = FALSE, libdir = "lib")
  page <- open_saved_page(file.path(dir, "w.html"))
  expect_equal(page$atoms, 327)
  expect_equal(page$errors, character())
  # The page and its lib folder work on their own (e.g. copied to a web server)
  moved <- withr::local_tempdir()
  file.copy(list.files(dir, full.names = TRUE), moved, recursive = TRUE)
  page <- open_saved_page(file.path(moved, "w.html"))
  expect_equal(page$atoms, 327)
  expect_equal(page$ngl, "2.5.0")
  expect_equal(page$errors, character())
})

test_that("an R Markdown document renders the widget, self-contained or not", {
  skip_if_no_browser()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("callr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  for (self_contained in c(TRUE, FALSE)) {
    dir <- withr::local_tempdir()
    rmd <- file.path(dir, "doc.Rmd")
    writeLines(c(
      "---",
      "title: test",
      "output:",
      "  html_document:",
      sprintf("    self_contained: %s", tolower(self_contained)),
      "---",
      "```{r, echo = FALSE}",
      sprintf("pkgload::load_all(%s, quiet = TRUE, export_all = FALSE)", deparse(pkg_root())),
      sprintf("NGLVieweR(%s) %%>%% addRepresentation('cartoon')",
              deparse(normalizePath(fixture("1crn.pdb")))),
      "```"
    ), rmd)
    # A separate R process: load_all() in the document would reload the
    # package in the test session
    out <- callr::r(function(rmd) rmarkdown::render(rmd, quiet = TRUE), list(rmd))
    page <- open_saved_page(out)
    expect_equal(page$atoms, 327, label = paste("self_contained", self_contained))
    expect_equal(page$errors, character(), label = paste("self_contained", self_contained))
    if (!self_contained) {
      ngl <- list.files(dir, "^ngl\\.js$", recursive = TRUE)
      expect_length(ngl, 1)
    }
  }
})
