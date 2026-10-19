# Bug #29: the widget's JavaScript dependencies (NGL.js, helperFunctions.js
# and the binding NGLVieweR.js) must each be copied exactly once when a widget
# is saved with its files next to it (saveWidget(selfcontained = FALSE),
# R Markdown/Quarto with self_contained: false, pkgdown).

widget_deps <- function() {
  w <- NGLVieweR(fixture("1crn.pdb"))
  deps <- htmltools::findDependencies(htmltools::as.tags(w))
  stats::setNames(deps, vapply(deps, `[[`, "", "name"))
}

test_that("the widget dependencies copy only their own scripts", {
  deps <- widget_deps()
  expect_true(all(c("NGLVieweR", "helperFunctions", "NGLVieweR-binding") %in% names(deps)))
  # (The binding dependency is created by htmlwidgets, not by NGLVieweR.yaml.)
  for (name in c("NGLVieweR", "helperFunctions")) {
    expect_false(isTRUE(deps[[name]]$all_files), label = paste(name, "all_files"))
  }
  expect_equal(deps$NGLVieweR$version, "2.5.0")
  # yaml reads "version: 1.0" as the number 1
  expect_equal(deps$helperFunctions$version, "1")
})

test_that("every listed script exists in the package", {
  for (dep in widget_deps()[c("NGLVieweR", "helperFunctions", "NGLVieweR-binding")]) {
    for (script in unlist(dep$script)) {
      dir <- if (is.null(dep$package)) dep$src$file else system.file(dep$src$file, package = dep$package)
      expect_true(file.exists(file.path(dir, script)),
                  label = paste(dep$name, script))
    }
  }
})

test_that("a widget saved with selfcontained = FALSE has each script once", {
  dir <- withr::local_tempdir()
  w <- NGLVieweR(fixture("1crn.pdb")) %>% addRepresentation("cartoon")
  htmlwidgets::saveWidget(w, file.path(dir, "w.html"), selfcontained = FALSE,
                          libdir = "lib")
  files <- list.files(file.path(dir, "lib"), recursive = TRUE, all.files = TRUE)
  expect_setequal(files[grepl("^(NGLVieweR|helperFunctions)-[0-9]", files)], c(
    "NGLVieweR-2.5.0/lib/NGL-2.5.0/ngl.js",
    "helperFunctions-1/lib/helperFunctions.js"
  ))
  binding <- paste0("NGLVieweR-binding-", packageVersion("NGLVieweR"), "/NGLVieweR.js")
  expect_true(binding %in% files)
  # The binding folder is htmlwidgets' own; recent versions copy only the
  # binding script there, so ngl.js is then written once in total.
  if (!isTRUE(widget_deps()[["NGLVieweR-binding"]]$all_files)) {
    expect_equal(sum(basename(files) == "ngl.js"), 1)
  }
  expected <- c("NGLVieweR-2.5.0/lib/NGL-2.5.0/ngl.js",
                "helperFunctions-1/lib/helperFunctions.js", binding)
  # The page loads them from those places
  html <- paste(readLines(file.path(dir, "w.html"), warn = FALSE), collapse = "\n")
  html <- gsub("/./", "/", html, fixed = TRUE)
  for (f in expected) {
    expect_true(grepl(paste0('src="lib/', f, '"'), html, fixed = TRUE), label = f)
  }
})

test_that("a self-contained widget embeds NGL.js, the helpers and the binding", {
  # saveWidget(selfcontained = TRUE) uses pandoc
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  file <- withr::local_tempfile(fileext = ".html")
  htmlwidgets::saveWidget(NGLVieweR(fixture("1crn.pdb")), file, selfcontained = TRUE)
  html <- paste(readLines(file, warn = FALSE), collapse = "\n")
  has <- function(x) grepl(x, html, fixed = TRUE)
  expect_true(has("function colorMaker"))   # helperFunctions.js
  expect_true(has("HTMLWidgets.widget"))     # NGLVieweR.js
  expect_true(has("StructureComponent"))    # ngl.js
  expect_false(has('<script src="'))         # nothing loaded from files
})
