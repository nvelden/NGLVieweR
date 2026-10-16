# Regenerates the test fixtures in tests/testthat/fixtures/.
# Run from the project root: Rscript dev/make-fixtures.R
#
# 1crn.pdb          crambin (1 chain, 46 residues); the source file, not regenerated.
# 1crn_moved.pdb    1crn rotated 40 deg about z, then translated +25 A along x.
# 1crn_moved2.pdb   1crn rotated 70 deg about x, then translated -30 A along y.
# 1crn_lines.rds    readLines("1crn.pdb"), a character vector of lines (for #7).
# broken.pdb        random text that no structure parser accepts (for #8).

fixtures <- "tests/testthat/fixtures"
src <- readLines(file.path(fixtures, "1crn.pdb"))

rot_z <- function(deg) {
  a <- deg * pi / 180
  matrix(c(cos(a), -sin(a), 0,
           sin(a),  cos(a), 0,
           0,       0,      1), 3, byrow = TRUE)
}
rot_x <- function(deg) {
  a <- deg * pi / 180
  matrix(c(1, 0,       0,
           0, cos(a), -sin(a),
           0, sin(a),  cos(a)), 3, byrow = TRUE)
}

# Applies x' = R %*% x + t to the coordinates (columns 31-54) of ATOM/HETATM
# records and leaves every other line unchanged.
transform_pdb <- function(lines, R, t) {
  is_atom <- grepl("^(ATOM  |HETATM)", lines)
  xyz <- cbind(
    as.numeric(substr(lines[is_atom], 31, 38)),
    as.numeric(substr(lines[is_atom], 39, 46)),
    as.numeric(substr(lines[is_atom], 47, 54))
  )
  new <- t(R %*% t(xyz) + t)
  coords <- sprintf("%8.3f%8.3f%8.3f", new[, 1], new[, 2], new[, 3])
  lines[is_atom] <- paste0(substr(lines[is_atom], 1, 30), coords,
                           substring(lines[is_atom], 55))
  lines
}

writeLines(transform_pdb(src, rot_z(40), c(25, 0, 0)),
           file.path(fixtures, "1crn_moved.pdb"))
writeLines(transform_pdb(src, rot_x(70), c(0, -30, 0)),
           file.path(fixtures, "1crn_moved2.pdb"))
saveRDS(src, file.path(fixtures, "1crn_lines.rds"), version = 2)
writeLines(c("this is not a structure file",
             "qwerty 12 abc ### 3.14 zzz",
             "END?"),
           file.path(fixtures, "broken.pdb"))
