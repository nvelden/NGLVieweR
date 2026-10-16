# Bug #11: input$<id>_residues is a data frame with one row per residue and
# the same shape for one or several structures. The older _sequence, _resno
# and _chainname inputs keep their behaviour.

shapes_app <- function(n, env = parent.frame()) {
  make_app(c(
    "files <- file.path(fixture_dir, c('1crn.pdb', '1crn_moved2.pdb'))",
    sprintf("n <- %d", n),
    "ui <- fluidPage(NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    w <- NGLVieweR(files[1]) %>% addRepresentation('cartoon')",
    "    if (n == 2) w <- w %>% addStructure(files[2]) %>% addRepresentation('cartoon')",
    "    w",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

crambin <- strsplit("TTCCPSIVARSNFNVCRLPGTPEAICATYTGCIIIPGATCPGDYAN", "")[[1]]
cols <- c("structure", "chain", "resno", "inscode", "resname", "letter")

test_that("one structure: _residues has one row per residue", {
  skip_if_no_browser()
  app <- start_app(shapes_app(1))
  app$wait_for_value(input = "viewer_residues", ignore = list(NULL))
  res <- app$get_value(input = "viewer_residues")
  expect_s3_class(res, "data.frame")
  expect_equal(names(res), cols)
  expect_equal(nrow(res), 46)
  expect_equal(res$structure, rep(1L, 46))
  expect_equal(res$resno, 1:46)
  expect_equal(res$letter, crambin)
  expect_equal(res$resname[1:3], c("THR", "THR", "CYS"))
  # Older inputs unchanged
  expect_equal(app$get_value(input = "viewer_sequence"), crambin)
  expect_equal(app$get_value(input = "viewer_resno"), 1:46)
})

test_that("two structures: _residues keeps the same shape", {
  skip_if_no_browser()
  app <- start_app(shapes_app(2))
  app$wait_for_value(input = "viewer_residues", ignore = list(NULL))
  res <- app$get_value(input = "viewer_residues")
  expect_equal(names(res), cols)
  expect_equal(nrow(res), 92)
  expect_equal(res$structure, rep(1:2, each = 46))
  s2 <- res[res$structure == 2, ]
  expect_equal(s2$letter, crambin)
  expect_equal(s2$resno, 1:46)
  expect_type(s2$resno, "integer")
  # Older inputs unchanged (one joined string per structure)
  expect_equal(app$get_value(input = "viewer_sequence"),
               rep(paste(crambin, collapse = ""), 2))
})
