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
