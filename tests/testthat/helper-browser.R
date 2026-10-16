# Helpers for the browser tests (test-browser-*.R). These run a Shiny app in
# headless Chrome with shinytest2 and read NGL state through JavaScript.
#
# The app runs in a separate R process, so it must load the package itself.
# It loads the source tree with pkgload::load_all(), not the installed
# package, so the tests always exercise the working-tree JavaScript.

pkg_root <- function() normalizePath(test_path("..", ".."), mustWork = FALSE)

skip_if_no_browser <- function() {
  skip_on_cran()
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if_not_installed("pkgload")
  # Under R CMD check the tests run from a copy without the package source.
  skip_if_not(file.exists(file.path(pkg_root(), "DESCRIPTION")),
              "package source tree not available")
}

# Writes `code` (a character vector of app.R lines) to a temporary app folder
# whose first line loads the working-tree package. Fixtures are referenced
# from app code as `fixture_dir`.
make_app <- function(code, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  header <- c(
    sprintf("pkgload::load_all(%s, quiet = TRUE, export_all = FALSE)", deparse(pkg_root())),
    sprintf("fixture_dir <- %s", deparse(normalizePath(test_path("fixtures")))),
    "library(shiny)"
  )
  code <- code[!grepl("^\\s*library\\((NGLVieweR|shiny)\\)\\s*$", code)]
  writeLines(c(header, code), file.path(dir, "app.R"))
  dir
}

# Starts an app and waits until the widget `id` has loaded its structures.
start_app <- function(app_dir, id = "viewer", name = basename(app_dir),
                      env = parent.frame()) {
  app <- shinytest2::AppDriver$new(
    app_dir, name = name, timeout = 30000, load_timeout = 30000,
    height = 800, width = 1000
  )
  withr::defer(app$stop(), envir = env)
  wait_for_structures(app, id)
  app
}

wait_for_structures <- function(app, id = "viewer", timeout = 30000) {
  app$wait_for_js(sprintf(
    "(function(){ var w = HTMLWidgets.find('#%s');
       return !!(w && w.getStructure() && w.getStructure().length > 0); })()",
    id), timeout = timeout)
}

# Evaluates a JS expression with `w` bound to the widget and `stage` to its stage.
widget_js <- function(app, expr, id = "viewer") {
  app$get_js(sprintf(
    "(function(){ var w = HTMLWidgets.find('#%s'); var stage = w.getStage(); return (%s); })()",
    id, expr))
}

# Browser console errors: console.error() calls ("error") and uncaught
# exceptions and promise rejections ("throw").
console_errors <- function(app) {
  logs <- as.data.frame(app$get_logs())
  logs[logs$location == "chromote" & logs$level %in% c("error", "throw"),
       "message", drop = TRUE]
}
