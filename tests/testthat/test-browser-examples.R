# Smoke test: every example app in inst/examples loads its structures without
# browser console errors. The examples fetch structures from RCSB.

examples <- list.dirs(file.path(pkg_root(), "inst", "examples"),
                      recursive = FALSE, full.names = TRUE)

for (ex in examples) {
  test_that(paste("example", basename(ex), "loads without console errors"), {
    skip_if_no_browser()
    skip_if_offline("files.rcsb.org")
    code <- readLines(file.path(ex, "app.R"), warn = FALSE)
    app <- start_app(make_app(code), id = "structure", name = basename(ex))
    expect_equal(console_errors(app), character())
  })
}
