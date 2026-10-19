#'Color residues by value
#'
#'@description Color residues by a numeric value computed in R, such as a
#'  conservation score, a mutation effect or a p-value. The values are mapped
#'  onto a color gradient, and the result can be used as \code{color} wherever
#'  a representation takes one: \code{\link{addRepresentation}},
#'  \code{\link{addSelection}}, \code{\link{updateColor}} and
#'  \code{\link{updateRepresentation}}.
#'@param values Either a data frame with columns \code{resno} and
#'  \code{value}, and optionally \code{chain}, \code{inscode} (insertion code)
#'  and \code{structure} (the structure number, counting from 1); or a named
#'  numeric vector with names \code{"chain:resno"}, such as \code{"A:12"},
#'  \code{"A:12B"} (with insertion code \code{B}) or \code{"12"} (any chain).
#'  Without \code{chain} a row applies to that residue number in every chain,
#'  and without \code{structure} to every structure. The data frame of the
#'  Shiny input \code{input$<outputId>_residues} with an added \code{value}
#'  column can be used as is.
#'@param palette Two or more colors (names or HEX codes) for the gradient,
#'  from the lowest to the highest value.
#'@param domain The values at the two ends of the palette, \code{c(min, max)}.
#'  Defaults to the range of \code{values}. Values outside it get the color of
#'  the nearest end.
#'@param na_color Color for residues with a missing value (\code{NA}) and for
#'  residues not listed in \code{values}.
#'@details The colors are computed in R, so the viewer shows exactly the
#'  colors that \code{grDevices::colorRamp(palette)} gives. A row for a
#'  specific chain or structure takes precedence over a row for any chain or
#'  structure. NGL.js cannot show a color legend; the returned object
#'  contains \code{palette} and \code{domain} (as HEX colors and numbers) so a
#'  legend can be drawn next to the viewer, e.g. with a plot.
#'@return A \code{NGLVieweR_colorByValue} object to use as \code{color}.
#'@seealso [addRepresentation()], [updateColor()], [NGLVieweR-shiny]
#' @examples
#' scores <- data.frame(chain = "A", resno = 1:46, value = sin(1:46 / 5))
#' NGLVieweR("1CRN") %>%
#'   addRepresentation("cartoon",
#'     param = list(color = colorByValue(scores,
#'                                       palette = c("blue", "white", "red"),
#'                                       domain = c(-1, 1))))
#'
#' # A named vector, for a few residues; all others are grey
#' NGLVieweR("1CRN") %>%
#'   addRepresentation("cartoon",
#'     param = list(color = colorByValue(c("A:10" = 1, "A:20" = 2, "A:30" = 3))))
#'
#' if (interactive()) {
#'   library(shiny)
#'   ui <- fluidPage(
#'     sliderInput("k", "Score = sin(resno / k)", 1, 20, 5),
#'     NGLVieweROutput("structure")
#'   )
#'   server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("1CRN") %>%
#'         addRepresentation("cartoon", param = list(name = "cartoon"))
#'     })
#'     observeEvent(input$k, {
#'       residues <- input$structure_residues
#'       req(residues)
#'       residues$value <- sin(residues$resno / input$k)
#'       NGLVieweR_proxy("structure") %>%
#'         updateColor("cartoon", colorByValue(residues, domain = c(-1, 1)))
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'@importFrom grDevices col2rgb colorRamp rgb
#'@export
colorByValue <- function(values, palette = c("blue", "white", "red"), domain = NULL,
                         na_color = "grey") {
  fail <- function(...) stop("colorByValue: ", ..., call. = FALSE)

  rows <- .value_rows(values, fail)

  # is.na() marks "any chain/structure", so it cannot clash with a chain named "NA"
  key <- paste(is.na(rows$structure), rows$structure, is.na(rows$chain), rows$chain,
               rows$resno, rows$inscode, sep = "\r")
  if (anyDuplicated(key)) {
    i <- which(duplicated(key))[1]
    fail("a residue is given more than once: ", .residue_label(rows[i, ]))
  }

  if (length(palette) < 2) fail("'palette' needs at least two colors.")
  palette <- .hex_colors(palette, "palette", fail)
  na_color <- .hex_colors(na_color, "na_color", fail)
  if (length(na_color) != 1) fail("'na_color' must be one color.")

  value <- as.numeric(rows$value)
  if (is.null(domain)) {
    if (!any(is.finite(value))) {
      fail("there are no finite values, so 'domain' cannot be taken from them; give 'domain'.")
    }
    domain <- range(value, na.rm = TRUE, finite = TRUE)
  }
  if (!is.numeric(domain) || length(domain) != 2 || anyNA(domain) ||
      any(!is.finite(domain)) || domain[1] > domain[2]) {
    fail("'domain' must be two numbers c(min, max) with min <= max.")
  }

  # Position on the palette, 0 to 1. With equal ends a value at the domain
  # gets the middle color and one outside it the nearest end; missing values
  # stay NA, so they get na_color.
  pos <- if (domain[1] == domain[2]) (sign(value - domain[1]) + 1) / 2 else
    (value - domain[1]) / (domain[2] - domain[1])
  pos <- pmin(pmax(pos, 0), 1)
  color <- rep(na_color, length(value))
  ok <- !is.na(pos)
  if (any(ok)) {
    color[ok] <- rgb(colorRamp(palette)(pos[ok]), maxColorValue = 255)
  }

  # I() keeps vectors of length 1 as arrays in JSON
  structure(
    list(type = "values",
         structure = I(rows$structure),
         chain = I(rows$chain),
         resno = I(rows$resno),
         inscode = I(rows$inscode),
         color = I(color),
         na_color = na_color,
         palette = I(palette),
         domain = I(as.numeric(domain))),
    class = "NGLVieweR_colorByValue"
  )
}

# The rows of colorByValue() input as a data frame with columns structure
# (integer, NA = every structure), chain (NA = any chain), resno (integer),
# inscode ("" = none) and value.
.value_rows <- function(values, fail) {
  if (is.data.frame(values)) {
    for (col in c("resno", "value")) {
      if (!col %in% names(values)) {
        fail("'values' needs a '", col, "' column; it has: ",
             paste(names(values), collapse = ", "), ".")
      }
    }
    n <- nrow(values)
    rows <- data.frame(
      structure = if ("structure" %in% names(values)) values$structure else rep(NA_integer_, n),
      chain = if ("chain" %in% names(values)) as.character(values$chain) else rep(NA_character_, n),
      resno = values$resno,
      inscode = if ("inscode" %in% names(values)) as.character(values$inscode) else rep("", n),
      value = values$value,
      stringsAsFactors = FALSE
    )
  } else if (is.numeric(values) || (is.logical(values) && all(is.na(values)))) {
    nms <- names(values)
    pattern <- "^(?:([^:]+):)?(-?[0-9]+)([A-Za-z]?)$"
    if (is.null(nms) || anyNA(nms) || !all(grepl(pattern, nms, perl = TRUE))) {
      fail("the names of 'values' must look like \"A:12\", \"A:12B\" or \"12\".")
    }
    parts <- regmatches(nms, regexec(pattern, nms, perl = TRUE))
    part <- function(i) vapply(parts, `[`, "", i)
    chain <- part(2)
    rows <- data.frame(structure = rep(NA_integer_, length(values)),
                       chain = ifelse(chain == "", NA_character_, chain),
                       resno = as.numeric(part(3)), inscode = part(4),
                       value = unname(values), stringsAsFactors = FALSE)
  } else {
    fail("'values' must be a data frame or a named numeric vector.")
  }

  if (nrow(rows) == 0) fail("'values' has no rows.")
  if (!is.numeric(rows$value) && !all(is.na(rows$value))) {
    fail("'value' must be numeric.")
  }
  if (!is.numeric(rows$resno) || anyNA(rows$resno) || any(rows$resno != round(rows$resno))) {
    fail("'resno' must be whole numbers.")
  }
  s <- rows$structure
  if (!all(is.na(s)) &&
      (!is.numeric(s) || any(s[!is.na(s)] < 1) || any(s[!is.na(s)] != round(s[!is.na(s)])))) {
    fail("'structure' must be structure numbers (whole numbers from 1), or NA for all.")
  }
  rows$structure <- as.integer(s)
  rows$resno <- as.integer(rows$resno)
  rows$inscode[is.na(rows$inscode)] <- ""
  rows
}

# "A:12B" style label of a row of .value_rows(), for error messages.
.residue_label <- function(row) {
  label <- paste0(if (!is.na(row$chain)) paste0(row$chain, ":"), row$resno, row$inscode)
  if (!is.na(row$structure)) label <- paste0(label, " (structure ", row$structure, ")")
  label
}

# Colors as "#RRGGBB" (alpha is dropped: NGL colors are opaque).
.hex_colors <- function(x, what, fail) {
  # Numbers would be palette() indices, not what the user means
  rgb_values <- if (is.character(x)) tryCatch(col2rgb(x), error = function(e) NULL)
  if (is.null(rgb_values) || anyNA(x)) {
    fail("'", what, "' contains a color that is not a color name or HEX code.")
  }
  rgb(t(rgb_values), maxColorValue = 255)
}
