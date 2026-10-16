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
  s <- x$structures[[1]]
  expect_equal(s$setScale, 1)
  expect_equal(s$addRepresentation, list(type = list(), values = list()))
  expect_equal(s$setRotation, list())
  expect_equal(s$setPosition, list())
  expect_equal(s$zoomMove, list())
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
