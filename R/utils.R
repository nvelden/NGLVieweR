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

# Compression extensions: R decompresses these files when reading them.
.compression_exts <- c("gz", "bz2", "xz")

# Binary structure formats: reading them as text would corrupt them.
.binary_formats <- c("mmtf", "bcif")

# Extensions that mark a string as a structure file path.
.structure_exts <- c("pdb", "ent", "cif", "mmcif", "mcif", "pqr", "gro", "sdf",
                     "sd", "mol2", .binary_formats)

# Format from a file name, looking past a compression extension
# ("1crn.pdb.gz" -> "pdb").
.structure_file_ext <- function(path) {
  ext <- .file_ext(path)
  if (tolower(ext) %in% .compression_exts) {
    ext <- .file_ext(sub("\\.[[:alnum:]]+$", "", path))
  }
  ext
}

# TRUE if `x` is clearly meant as a file path: it contains a directory
# separator or ends in a structure or compression extension.
.looks_like_path <- function(x) {
  .could_be_path(x) &&
    (grepl("[/\\\\]", x) ||
       tolower(.file_ext(x)) %in% c(.structure_exts, .compression_exts))
}

# Works out whether `data` is a file path, file contents or a PDB code, and
# returns the structure fields list(type, data, file_ext). Shared by
# NGLVieweR() and addStructure() so both read the same input the same way.
# `caller` names the function in error messages.
.parse_structure_input <- function(data, format, caller) {
  fail <- function(...) stop(caller, ": ", ..., call. = FALSE)

  if (!is.character(data) || length(data) == 0 || anyNA(data) ||
      !any(nzchar(trimws(data)))) {
    fail("'data' must be a PDB entry code, a file path or file contents.")
  }
  if (!is.null(format)) {
    # Remove a leading dot from the format (".pdb" -> "pdb")
    if (is.character(format) && length(format) == 1 && !is.na(format)) {
      format <- sub("^\\.", "", format)
    }
    if (!is.character(format) || length(format) != 1 || is.na(format) ||
        !nzchar(format)) {
      fail("'format' must be a single file format such as \"pdb\".")
    }
  }

  # A vector of lines (e.g. from readLines()) is file contents
  if (length(data) > 1) {
    data <- paste(data, collapse = "\n")
  }

  if (.could_be_path(data) && file.exists(data) && !dir.exists(data)) {
    # A file path
    .check_text_format(.structure_file_ext(data), fail)
    file_ext <- if (is.null(format)) .structure_file_ext(data) else format
    if (!nzchar(file_ext)) {
      fail("Please specify the file format")
    }
    data <- paste(readLines(data, warn = FALSE), collapse = "\n")
    type <- "file"
  } else if (grepl("^[[:alpha:]][[:alnum:]+.-]*://", data)) {
    fail("URLs are not supported; download the file first, e.g. with ",
         "download.file(), and pass the file path.")
  } else if (.looks_like_path(data)) {
    fail("file not found: ", data)
  } else if (grepl("[\r\n]", data, useBytes = TRUE) ||
             nchar(data, type = "bytes") > 8) {
    # File contents
    if (is.null(format)) {
      fail("Please specify the file format")
    }
    file_ext <- format
    type <- "file"
  } else {
    # A PDB code
    file_ext <- format
    type <- "code"
    data <- sprintf("rcsb://%s.pdb", data)
  }

  if (type == "file") {
    # NGL's format names are lower case
    file_ext <- tolower(file_ext)
    .check_text_format(file_ext, fail)
  }

  list(type = type, data = data, file_ext = file_ext)
}

.check_text_format <- function(file_ext, fail) {
  if (tolower(file_ext) %in% .binary_formats) {
    fail("binary formats such as .", tolower(file_ext), " are not supported; ",
         "use a text format such as PDB or mmCIF.")
  }
}

# Works out the 1-based structure number for addSelection()/updateZoomMove().
# `structureIndex` is the deprecated 0-based form; it is converted with a
# warning. Returns NULL when neither is given (all / first structure).
.resolve_structure <- function(structure, structureIndex, caller) {
  if (!is.null(structureIndex)) {
    if (!is.null(structure)) {
      stop(caller, ": use either 'structure' or 'structureIndex', not both.", call. = FALSE)
    }
    # The old argument stays lenient: values it never accepted (e.g. "1" from
    # a selectInput) applied to all structures before, so they still do.
    if (!is.numeric(structureIndex) || length(structureIndex) != 1 ||
        !is.finite(structureIndex) || structureIndex < 0 ||
        structureIndex != round(structureIndex)) {
      warning(caller, ": 'structureIndex' must be a whole number of 0 or more; ",
              "it is ignored. Use 'structure', which counts from 1.", call. = FALSE)
      return(NULL)
    }
    warning(caller, ": 'structureIndex' is deprecated; use 'structure', which counts ",
            "from 1 (structure = structureIndex + 1).", call. = FALSE)
    structure <- structureIndex + 1
  }
  if (!is.null(structure) &&
      (!is.numeric(structure) || length(structure) != 1 || !is.finite(structure) ||
       structure < 1 || structure != round(structure))) {
    stop(caller, ": 'structure' must be a single whole number of 1 or more.", call. = FALSE)
  }
  structure
}
