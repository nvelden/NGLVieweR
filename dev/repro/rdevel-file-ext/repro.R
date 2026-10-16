# Repro for the R-devel bug: NGLVieweR() fails on file contents.
# Run from the project root:
#   source("dev/repro/rdevel-file-ext/repro.R")
#
# R-devel's tools::file_ext() calls basename(). On R-devel basename() errors
# for strings longer than PATH_MAX (4096 characters); R 4.4 only warns. This
# script swaps in R-devel's file_ext() with that error, so the failure shows
# on the current R as well.

pkgload::load_all(".", quiet = TRUE)

devel_file_ext <- function(x) {
  x <- as.character(x)
  if (any(nchar(x) > 4095)) stop("basename(x): path too long")
  ifelse(grepl("^(.*[^.]+.*)[.]([[:alnum:]]+)$", basename(x)),
         sub(".*[.]([[:alnum:]]+)$", "\\1", x), "")
}

pdb_text <- paste(readLines("tests/testthat/fixtures/1crn.pdb"), collapse = "\n")
cat("Length of the PDB text:", nchar(pdb_text), "characters\n\n")

testthat::with_mocked_bindings(
  {
    cat("NGLVieweR(pdb_text, format = 'pdb'):\n")
    print(tryCatch({ NGLVieweR(pdb_text, format = "pdb"); "OK" },
                   error = function(e) paste("ERROR:", conditionMessage(e))))
    cat("\naddStructure(pdb_text, format = 'pdb'):\n")
    print(tryCatch({ NGLVieweR("1CRN") %>% addStructure(pdb_text, format = "pdb"); "OK" },
                   error = function(e) paste("ERROR:", conditionMessage(e))))
    cat("\nNGLVieweR('1CRN') (short input, unaffected):\n")
    print(tryCatch({ NGLVieweR("1CRN"); "OK" },
                   error = function(e) paste("ERROR:", conditionMessage(e))))
  },
  file_ext = devel_file_ext, .package = "tools"
)
