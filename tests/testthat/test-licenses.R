# The bundled NGL.js ships without its license comments, so its notices are in
# inst/COPYRIGHTS and next to the file. Updating NGL.js must update them too.

test_that("the bundled NGL.js comes with its license and notices", {
  deps <- htmlwidgets::getDependency("NGLVieweR", "NGLVieweR")
  dep <- Filter(function(d) d$name == "NGLVieweR", deps)[[1]]
  dir <- if (is.null(dep$package)) dep$src$file else
    system.file(dep$src$file, package = dep$package)
  ngl <- file.path(dir, dep$script)
  expect_true(file.exists(ngl))

  license <- readLines(file.path(dirname(ngl), "LICENSE"))
  expect_true(any(grepl("Copyright (c) 2014-2017, Alexander S Rose", license,
                        fixed = TRUE)))

  copyrights_file <- system.file("COPYRIGHTS", package = "NGLVieweR")
  expect_true(nzchar(copyrights_file))
  copyrights <- readLines(copyrights_file, encoding = "UTF-8")
  expect_true(any(grepl(paste0("NGL.js ", dep$version, " "), copyrights,
                        fixed = TRUE)))
  # The checksum recorded in COPYRIGHTS is the one of the bundled file
  md5 <- sub("^MD5: +", "", grep("^MD5:", copyrights, value = TRUE))
  expect_identical(md5, unname(tools::md5sum(ngl)))
  libs <- c("three.js", "Mol*", "chroma.js", "sprintf.js", "JS Signals", "tslib")
  for (lib in libs) {
    expect_true(any(startsWith(trimws(copyrights), lib)), label = lib)
  }
})
