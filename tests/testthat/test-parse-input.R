# Bug #7: input edge cases of .parse_structure_input(), checked through both
# NGLVieweR() and addStructure().

# The structure entry each function builds for the same arguments.
both <- function(...) {
  list(
    NGLVieweR = NGLVieweR(...)$x$structures[[1]],
    addStructure = (NGLVieweR("1CRN") %>% addStructure(...))$x$structures[[2]]
  )
}
expect_error_both <- function(..., regexp) {
  expect_error(NGLVieweR(...), regexp)
  expect_error(NGLVieweR("1CRN") %>% addStructure(...), regexp)
}

pdb_lines <- readLines(test_path("fixtures", "1crn.pdb"))
pdb_text <- paste(pdb_lines, collapse = "\n")

test_that("7a: a path that does not exist is an error, not file contents", {
  expect_error_both("data/model.pdb", regexp = "file not found: data/model.pdb")
  expect_error_both("C:\\data\\model.cif", regexp = "file not found")
  expect_error_both("model.pdb", regexp = "file not found: model.pdb")
  expect_error_both("data/model.pdb", format = "pdb", regexp = "file not found")
})

test_that("7a: PDB codes are still codes", {
  for (s in both("1CRN")) expect_equal(s$data, "rcsb://1CRN.pdb")
  for (s in both("1crn")) expect_equal(s$data, "rcsb://1crn.pdb")
})

# Bug #20 (GitHub #17): large entries have no legacy .pdb file on RCSB.
test_that("#20: a PDB code without format loads .pdb with an mmCIF fallback", {
  for (s in both("1CRN")) {
    expect_equal(s$data, "rcsb://1CRN.pdb")
    expect_equal(s$fallback, "rcsb://1CRN.cif")
    expect_null(s$file_ext)
  }
})

test_that("#20: format picks the file for a PDB code, without fallback", {
  for (f in c("cif", "CIF", ".cif", "mmcif", "mcif")) {
    for (s in both("3J9M", format = f)) {
      expect_equal(s$data, "rcsb://3J9M.cif", label = f)
      expect_null(s$fallback)
      expect_equal(s$file_ext, "cif")
    }
  }
  for (f in c("pdb", "PDB", ".pdb", "ent")) {
    for (s in both("1CRN", format = f)) {
      expect_equal(s$data, "rcsb://1CRN.pdb", label = f)
      expect_null(s$fallback)
      expect_equal(s$file_ext, "pdb")
    }
  }
})

test_that("#20: other formats are an error for a PDB code", {
  expect_error_both("1CRN", format = "sdf",
                    regexp = "for a PDB code, 'format' must be \"pdb\" or \"cif\"")
  expect_error_both("1CRN", format = "mmtf", regexp = "for a PDB code")
})

test_that("#20: files are not given a fallback", {
  for (s in both(test_path("fixtures", "1crn.pdb"))) expect_null(s$fallback)
  for (s in both(pdb_text, format = "pdb")) expect_null(s$fallback)
})

test_that("7b: a vector of lines is file contents", {
  for (s in both(pdb_lines, format = "pdb")) {
    expect_equal(s$type, "file")
    expect_equal(s$file_ext, "pdb")
    expect_equal(s$data, pdb_text)
  }
  expect_error_both(pdb_lines, regexp = "Please specify the file format")
})

test_that("text with line breaks is file contents, however short", {
  for (s in both("C\nO", format = "sdf")) {
    expect_equal(s$type, "file")
    expect_equal(s$file_ext, "sdf")
    expect_equal(s$data, "C\nO")
  }
  expect_error_both("C\nO", regexp = "Please specify the file format")
})

test_that("7c: compressed text files are read with the inner extension", {
  dir <- withr::local_tempdir()
  for (ext in c("gz", "bz2", "xz")) {
    path <- file.path(dir, paste0("1crn.pdb.", ext))
    con <- switch(ext, gz = gzfile(path, "w"), bz2 = bzfile(path, "w"), xz = xzfile(path, "w"))
    writeLines(pdb_lines, con)
    close(con)
    for (s in both(path)) {
      expect_equal(s$type, "file")
      expect_equal(s$file_ext, "pdb", label = ext)
      expect_equal(s$data, pdb_text)
    }
  }
})

test_that("7c: binary formats give a clear error", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "1crn.mmtf")
  writeBin(as.raw(c(0xde, 0x00, 0x12, 0xff)), path)
  expect_error_both(path, regexp = "binary")
  expect_error_both(path, format = "pdb", regexp = "binary")
  expect_error_both(pdb_text, format = "mmtf", regexp = "binary")
  expect_error_both(pdb_text, format = "MMTF", regexp = "binary")
})

test_that("URLs give a clear error", {
  expect_error_both("https://files.rcsb.org/download/1CRN.cif", regexp = "URLs are not supported")
})

test_that("formats are passed in lower case", {
  dir <- withr::local_tempdir()
  file.copy(test_path("fixtures", "1crn.pdb"), file.path(dir, "1CRN.PDB"))
  for (s in both(file.path(dir, "1CRN.PDB"))) expect_equal(s$file_ext, "pdb")
  for (s in both(pdb_text, format = "PDB")) expect_equal(s$file_ext, "pdb")
})

test_that("files without a final newline are read without a warning", {
  path <- withr::local_tempfile(fileext = ".pdb")
  cat(pdb_text, file = path)
  expect_no_warning(s <- NGLVieweR(path)$x$structures[[1]])
  expect_equal(s$data, pdb_text)
})

test_that("an existing file without extension needs a format", {
  dir <- withr::local_tempdir()
  writeLines(pdb_lines, file.path(dir, "model"))
  withr::local_dir(dir)
  expect_error_both("model", regexp = "Please specify the file format")
  for (s in both("model", format = "pdb")) {
    expect_equal(s$type, "file")
    expect_equal(s$file_ext, "pdb")
  }
})

test_that("format must be a single non-empty string", {
  path <- test_path("fixtures", "1crn.pdb")
  for (bad in list(NA, "", ".", c("pdb", "cif"), 1)) {
    expect_error_both(path, format = bad, regexp = "format")
  }
})

test_that("data must be a non-missing character value", {
  for (bad in list(NA_character_, NA, 123, character(0), "", "   ")) {
    expect_error_both(bad, regexp = "data")
  }
})

test_that("plain files and contents still work as before", {
  path <- test_path("fixtures", "1crn.pdb")
  for (s in both(path)) {
    expect_equal(s$type, "file")
    expect_equal(s$file_ext, "pdb")
    expect_equal(s$data, pdb_text)
  }
  for (s in both(pdb_text, format = ".pdb")) {
    expect_equal(s$type, "file")
    expect_equal(s$file_ext, "pdb")
  }
})
