# TRUE if `x` could be a file path: a single string without line breaks and
# shorter than PATH_MAX. File contents (which always have line breaks) never
# qualify. They must not reach tools::file_ext() or file.exists(): in R-devel,
# file_ext() calls basename(), which errors on strings longer than PATH_MAX
# (4096 bytes on Linux).
.could_be_path <- function(x) {
  is.character(x) && length(x) == 1 && !is.na(x) &&
    nchar(x, type = "bytes") < 4096 && !grepl("[\r\n]", x)
}

# tools::file_ext() for strings that could be a path, "" otherwise.
.file_ext <- function(x) {
  if (.could_be_path(x)) tools::file_ext(x) else ""
}

# Works out whether `data` is a file path, file contents or a PDB code, and
# returns the structure fields list(type, data, file_ext). Shared by
# NGLVieweR() and addStructure() so both read the same input the same way.
# `caller` names the function in error messages.
.parse_structure_input <- function(data, format, caller) {
  if (is.character(data) && length(data) == 1 && nchar(data) > 8 &&
      .file_ext(data) == "" && is.null(format)) {
    stop(caller, ": Please specify the file format", call. = FALSE)
  }

  # Remove a leading dot from the format (".pdb" -> "pdb")
  if (!is.null(format) && startsWith(format, ".")) {
    format <- substr(format, 2, nchar(format))
  }

  file_ext <- format
  if (.could_be_path(data) && file.exists(data) && !dir.exists(data)) {
    # A file path
    if (is.null(format)) {
      file_ext <- .file_ext(data)
    }
    data <- paste(readLines(data), collapse = "\n")
    type <- "file"
  } else if (is.character(data) && length(data) == 1 && nchar(data) > 8) {
    # File contents
    type <- "file"
  } else {
    # A PDB code
    type <- "code"
    data <- sprintf("rcsb://%s.pdb", data)
  }

  list(type = type, data = data, file_ext = file_ext)
}
