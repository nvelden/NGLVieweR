test_that("a PDB code becomes an rcsb:// URL", {
  w <- NGLVieweR("7CID")
  s <- w$x$structures[[1]]
  expect_s3_class(w, "htmlwidget")
  expect_equal(s$type, "code")
  expect_equal(s$data, "rcsb://7CID.pdb")
  expect_null(s$file_ext)
})

test_that("a file path is read and its extension used as the format", {
  path <- fixture("1crn.pdb")
  s <- NGLVieweR(path)$x$structures[[1]]
  expect_equal(s$type, "file")
  expect_equal(s$file_ext, "pdb")
  expect_equal(s$data, paste(readLines(path), collapse = "\n"))
})

test_that("an explicit format overrides the file extension, leading dot removed", {
  s <- NGLVieweR(fixture("1crn.pdb"), format = ".cif")$x$structures[[1]]
  expect_equal(s$file_ext, "cif")
  expect_equal(s$type, "file")
})

test_that("a content string with a format is passed as file contents", {
  txt <- paste(readLines(fixture("1crn.pdb")), collapse = "\n")
  s <- NGLVieweR(txt, format = "pdb")$x$structures[[1]]
  expect_equal(s$type, "file")
  expect_equal(s$file_ext, "pdb")
  expect_equal(s$data, txt)
})

test_that("file contents work with R-devel's tools::file_ext() (#17)", {
  # R-devel's file_ext() calls basename(), which errors for strings longer
  # than PATH_MAX. Simulate that so the test fails on any R version.
  devel_file_ext <- function(x) {
    x <- as.character(x)
    if (any(nchar(x) > 4095)) stop("basename(x): path too long")
    ifelse(grepl("^(.*[^.]+.*)[.]([[:alnum:]]+)$", basename(x)),
           sub(".*[.]([[:alnum:]]+)$", "\\1", x), "")
  }
  local_mocked_bindings(file_ext = devel_file_ext, .package = "tools")
  txt <- paste(readLines(fixture("1crn.pdb")), collapse = "\n")

  s <- NGLVieweR(txt, format = "pdb")$x$structures[[1]]
  expect_equal(s$type, "file")
  expect_equal(s$file_ext, "pdb")
  expect_equal(s$data, txt)

  s <- (NGLVieweR("1CRN") %>% addStructure(txt, format = "pdb"))$x$structures[[2]]
  expect_equal(s$type, "file")
  expect_equal(s$file_ext, "pdb")
  expect_equal(s$data, txt)

  expect_error(NGLVieweR(txt), "Please specify the file format")
  expect_error(NGLVieweR("1CRN") %>% addStructure(txt), "Please specify the file format")

  # Paths and codes still use file_ext() / file.exists() as before.
  expect_equal(NGLVieweR(fixture("1crn.pdb"))$x$structures[[1]]$file_ext, "pdb")
  expect_equal(NGLVieweR("1CRN")$x$structures[[1]]$type, "code")
})

test_that("missing data and missing format give clear errors", {
  expect_error(NGLVieweR(), "Please specify a PDB entry code or file")
  expect_error(NGLVieweR("HEADER    PLANT PROTEIN"), "Please specify the file format")
  expect_error(addStructure(NGLVieweR("1CRN")), "Please specify a PDB entry code or file")
  expect_error(addStructure(NGLVieweR("1CRN"), "HEADER    PLANT PROTEIN"),
               "Please specify the file format")
})

test_that("NGLVieweR() sets the documented stage defaults", {
  x <- NGLVieweR("1CRN")$x
  expect_equal(x$setQuality, "medium")
  expect_false(x$setRock)
  expect_false(x$setSpin)
  expect_equal(x$setFocus, 0)
  expect_equal(x$stageParameters, list())
  expect_equal(x$superpose, list())
  # toggleRock/toggleSpin were never settable from R and are not sent.
  expect_null(x$toggleRock)
  expect_null(x$toggleSpin)
  s <- x$structures[[1]]
  expect_equal(s$setScale, 1)
  expect_equal(s$addRepresentation, list(type = list(), values = list()))
  expect_equal(s$setRotation, list())
  expect_equal(s$setPosition, list())
  expect_equal(s$zoomMove, list())
})

test_that("structures carry no stage-wide spin/rock fields (#14)", {
  s <- (NGLVieweR("1CRN") %>% addStructure("7CID"))$x$structures[[2]]
  for (f in c("setRock", "setSpin", "toggleRock", "toggleSpin")) expect_null(s[[f]], label = f)
  expect_equal(names((NGLVieweR("1CRN"))$x$structures[[1]]), names(s))
})

test_that("addStructure() appends a code or a long file path", {
  path <- fixture("1crn_moved.pdb")
  x <- (NGLVieweR("1CRN") %>% addStructure("7CID") %>% addStructure(path))$x
  expect_length(x$structures, 3)
  expect_equal(x$structures[[2]]$type, "code")
  expect_equal(x$structures[[2]]$data, "rcsb://7CID.pdb")
  expect_equal(x$structures[[3]]$type, "file")
  expect_equal(x$structures[[3]]$file_ext, "pdb")
  expect_equal(x$structures[[3]]$data, paste(readLines(path), collapse = "\n"))
})

test_that("NGLVieweR() and addStructure() parse the same input the same way (#6)", {
  # Work in a folder that contains 1crn.pdb, so "1crn.pdb" (8 characters)
  # is a file in the working directory.
  dir <- withr::local_tempdir()
  file.copy(fixture("1crn.pdb"), dir)
  txt <- paste(readLines(fixture("1crn.pdb")), collapse = "\n")
  withr::local_dir(dir)

  inputs <- list(
    "PDB code" = list("1CRN"),
    "short file name" = list("1crn.pdb"),
    "full path" = list(normalizePath("1crn.pdb")),
    "format with leading dot" = list("1crn.pdb", format = ".pdb"),
    "contents with format" = list(txt, format = "pdb")
  )
  for (name in names(inputs)) {
    args <- inputs[[name]]
    a <- do.call(NGLVieweR, args)$x$structures[[1]]
    b <- (NGLVieweR("1CRN") %>% (function(w) do.call(addStructure, c(list(w), args))))$x$structures[[2]]
    expect_identical(b[c("type", "file_ext", "data")], a[c("type", "file_ext", "data")],
                     label = paste("addStructure() for", name))
  }

  # And both read the short file name as a file.
  s <- (NGLVieweR("1CRN") %>% addStructure("1crn.pdb"))$x$structures[[2]]
  expect_equal(s$type, "file")
  expect_equal(s$file_ext, "pdb")

  # A folder named like a PDB code is not a file.
  dir.create("7CID")
  expect_equal(NGLVieweR("7CID")$x$structures[[1]]$data, "rcsb://7CID.pdb")
  expect_equal((NGLVieweR("1CRN") %>% addStructure("7CID"))$x$structures[[2]]$data,
               "rcsb://7CID.pdb")
})

test_that("the residues input handler builds a data frame (#11)", {
  handler <- NGLVieweR:::.residues_input
  x <- list(structure = list(1L, 1L, 2L), chain = list("A", "A", "AA"),
            resno = list(1L, 2L, 1L), inscode = list("", "", "B"),
            resname = list("THR", "HOH", "GLY"), letter = list("T", "X", "G"))
  df <- handler(x, NULL, "x")
  expect_s3_class(df, "data.frame")
  expect_equal(names(df), c("structure", "chain", "resno", "inscode", "resname", "letter"))
  expect_equal(df$structure, c(1L, 1L, 2L))
  expect_equal(df$chain, c("A", "A", "AA"))
  expect_equal(df$resno, c(1L, 2L, 1L))
  expect_type(df$letter, "character")

  empty <- handler(list(structure = list(), chain = list(), resno = list(),
                        inscode = list(), resname = list(), letter = list()), NULL, "x")
  expect_equal(nrow(empty), 0)
  expect_equal(names(empty), names(df))
  expect_null(handler(NULL, NULL, "x"))

  # A missing value (JSON null) becomes NA and does not shift the columns
  y <- x
  y$chain[[2]] <- NULL
  y$chain <- append(y$chain, list(NULL), after = 1)
  y$resno[2] <- list(NULL)
  df <- handler(y, NULL, "x")
  expect_equal(nrow(df), 3)
  expect_equal(df$chain, c("A", NA, "AA"))
  expect_equal(df$resno, c(1L, NA, 1L))
})
