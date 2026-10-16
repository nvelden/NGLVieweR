# Smoke test: every example app in inst/examples loads its structures without
# browser console errors. The examples fetch structures from RCSB.

examples <- list.dirs(file.path(pkg_root(), "inst", "examples"),
                      recursive = FALSE, full.names = TRUE)

# Examples that cannot start in a non-interactive R process.
# See "Found during the work" in dev/BUGFIX_PLAN.md.
known_broken <- c(updateFullscreen = "app.R is wrapped in if (interactive())")

for (ex in examples) {
  test_that(paste("example", basename(ex), "loads without console errors"), {
    skip_if_no_browser()
    skip_if_offline("files.rcsb.org")
    skip_if(basename(ex) %in% names(known_broken), known_broken[basename(ex)])
    code <- readLines(file.path(ex, "app.R"), warn = FALSE)
    app <- start_app(make_app(code), id = "structure", name = basename(ex))
    expect_equal(console_errors(app), character())
  })
}
