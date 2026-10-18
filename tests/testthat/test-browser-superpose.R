# Bug #4: setSuperpose() must move every target onto the reference and leave
# the reference where it is. The fixtures are 1crn.pdb and two copies moved
# by a known rigid transform, so a correct superpose gives CA RMSD ~ 0.

superpose_app <- function(n, reference, env = parent.frame()) {
  make_app(c(
    "files <- file.path(fixture_dir, c('1crn.pdb', '1crn_moved.pdb', '1crn_moved2.pdb'))",
    sprintf("n <- %d; reference <- %d", n, reference),
    "ui <- fluidPage(NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    w <- NGLVieweR(files[1]) %>% addRepresentation('cartoon')",
    "    for (i in seq_len(n)[-1]) w <- w %>% addStructure(files[i]) %>% addRepresentation('cartoon')",
    "    w %>% setSuperpose(reference = reference, sele_reference = '1-46', sele_target = '1-46')",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# CA coordinates (n x 3) of every loaded structure, as currently positioned.
ca_coords <- function(app) {
  xyz <- widget_js(app, "w.getStructure().map(function(c) {
    var xyz = [];
    c.structure.eachAtom(function(a) { if (a.atomname === 'CA') xyz.push([a.x, a.y, a.z]); });
    return xyz; })")
  lapply(xyz, function(s) do.call(rbind, lapply(s, unlist)))
}

# CA coordinates (n x 3) from PDB text.
pdb_text_ca <- function(pdb) {
  l <- strsplit(pdb, "\n", fixed = TRUE)[[1]]
  l <- l[grepl("^ATOM", l) & substr(l, 13, 16) == " CA "]
  cbind(as.numeric(substr(l, 31, 38)), as.numeric(substr(l, 39, 46)),
        as.numeric(substr(l, 47, 54)))
}

# CA coordinates as written in a fixture file.
file_ca <- function(name) pdb_text_ca(paste(readLines(fixture(name)), collapse = "\n"))

rmsd <- function(a, b) sqrt(mean(rowSums((a - b)^2)))

files <- c("1crn.pdb", "1crn_moved.pdb", "1crn_moved2.pdb")

for (case in list(c(2, 1), c(2, 2), c(3, 1), c(3, 2), c(3, 3))) {
  n <- case[1]
  ref <- case[2]
  test_that(sprintf("superpose with %d structures, reference %d", n, ref), {
    skip_if_no_browser()
    app <- start_app(superpose_app(n, ref))
    app$wait_for_value(input = "viewer_PDB", ignore = list(NULL))
    ca <- ca_coords(app)
    expect_length(ca, n)

    # The reference stays where its file put it.
    expect_lt(rmsd(ca[[ref]], file_ca(files[ref])), 0.01)
    # Every structure lies on the reference.
    for (i in seq_len(n)) {
      expect_lt(rmsd(ca[[i]], ca[[ref]]), 0.1, label = sprintf("RMSD of structure %d to reference", i))
    }
    expect_equal(console_errors(app), character())
  })
}

test_that("a reference larger than the number of structures logs an error", {
  skip_if_no_browser()
  app <- start_app(superpose_app(2, 3))
  app$wait_for_value(input = "viewer_PDB", ignore = list(NULL))
  # Console messages reach the log asynchronously; poll for the error.
  errors <- character()
  for (i in 1:50) {
    errors <- console_errors(app)
    if (length(errors) > 0) break
    Sys.sleep(0.1)
  }
  expect_true(any(grepl("reference 3 is out of range: there are 2 structures", errors)))
  # Nothing was moved.
  ca <- ca_coords(app)
  expect_lt(rmsd(ca[[1]], file_ca(files[1])), 0.01)
  expect_lt(rmsd(ca[[2]], file_ca(files[2])), 0.01)
})

# Bug #27: input$<id>_PDB must hold the coordinates shown in the viewer,
# i.e. be written after superposition.

for (case in list(c(2, 1), c(3, 2))) {
  n <- case[1]
  ref <- case[2]
  test_that(sprintf("_PDB holds the superposed coordinates (%d structures, reference %d)", n, ref), {
    skip_if_no_browser()
    app <- start_app(superpose_app(n, ref))
    pdb <- unlist(app$wait_for_value(input = "viewer_PDB", ignore = list(NULL)))
    expect_length(pdb, n)
    ca <- ca_coords(app)
    for (i in seq_len(n)) {
      expect_lt(rmsd(pdb_text_ca(pdb[i]), ca[[i]]), 0.01,
                label = sprintf("RMSD of exported structure %d to displayed", i))
    }
    # The exported reference is still at its file position.
    expect_lt(rmsd(pdb_text_ca(pdb[ref]), file_ca(files[ref])), 0.01)
    expect_equal(console_errors(app), character())
  })
}

test_that("_PDB without superpose holds the file coordinates", {
  skip_if_no_browser()
  app <- start_app(make_app(c(
    "files <- file.path(fixture_dir, c('1crn.pdb', '1crn_moved.pdb'))",
    "ui <- fluidPage(NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    NGLVieweR(files[1]) %>% addRepresentation('cartoon') %>%",
    "      addStructure(files[2]) %>% addRepresentation('cartoon')",
    "  })",
    "}",
    "shinyApp(ui, server)"
  )))
  pdb <- unlist(app$wait_for_value(input = "viewer_PDB", ignore = list(NULL)))
  expect_length(pdb, 2)
  for (i in 1:2) {
    expect_lt(rmsd(pdb_text_ca(pdb[i]), file_ca(files[i])), 0.01)
  }
  expect_equal(console_errors(app), character())
})
