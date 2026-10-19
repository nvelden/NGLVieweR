# F1: colorByValue() maps values from R to residue colors.

bwr <- c("blue", "white", "red")

test_that("values map onto the palette over the domain", {
  cv <- colorByValue(data.frame(resno = 1:3, value = c(0, 0.5, 1)),
                     palette = bwr, domain = c(0, 1))
  expect_s3_class(cv, "NGLVieweR_colorByValue")
  expect_equal(cv$type, "values")
  expect_equal(as.integer(cv$resno), 1:3)
  expect_equal(as.character(cv$color), c("#0000FF", "#FFFFFF", "#FF0000"))
})

test_that("values outside the domain get the end colors", {
  cv <- colorByValue(data.frame(resno = 1:2, value = c(-5, 5)),
                     palette = bwr, domain = c(0, 1))
  expect_equal(as.character(cv$color), c("#0000FF", "#FF0000"))
})

test_that("the default domain is the range of the values", {
  cv <- colorByValue(data.frame(resno = 1:3, value = c(10, 15, 20)), palette = bwr)
  expect_equal(as.numeric(cv$domain), c(10, 20))
  expect_equal(as.character(cv$color), c("#0000FF", "#FFFFFF", "#FF0000"))
})

test_that("equal values do not fail and get the middle color", {
  cv <- colorByValue(data.frame(resno = 1:2, value = c(3, 3)), palette = bwr)
  expect_equal(as.character(cv$color), c("#FFFFFF", "#FFFFFF"))
})

test_that("missing values get na_color also when the domain ends are equal (#22)", {
  # One distinct value: the default domain is c(5, 5)
  cv <- colorByValue(data.frame(resno = 1:3, value = c(5, NA, NaN)),
                     palette = bwr, na_color = "green")
  expect_equal(as.numeric(cv$domain), c(5, 5))
  expect_equal(as.character(cv$color), c("#FFFFFF", "#00FF00", "#00FF00"))
  # Equal ends given as domain
  cv <- colorByValue(c("A:1" = 3, "A:2" = NA, "A:3" = NaN), palette = bwr,
                     domain = c(3, 3), na_color = "green")
  expect_equal(as.character(cv$color), c("#FFFFFF", "#00FF00", "#00FF00"))
})

test_that("with equal domain ends, values outside the domain get the nearest end", {
  cv <- colorByValue(c("A:1" = 1, "A:2" = 3, "A:3" = 5), palette = bwr,
                     domain = c(3, 3))
  expect_equal(as.character(cv$color), c("#0000FF", "#FFFFFF", "#FF0000"))
  # Infinite values do not set the default domain, which is then c(5, 5)
  cv <- colorByValue(c("A:1" = 5, "A:2" = Inf, "A:3" = -Inf), palette = bwr)
  expect_equal(as.character(cv$color), c("#FFFFFF", "#FF0000", "#0000FF"))
})

test_that("NA values get na_color, which is also sent for unlisted residues", {
  cv <- colorByValue(data.frame(resno = 1:3, value = c(0, NA, 1)), na_color = "grey")
  expect_equal(as.character(cv$color)[2], "#BEBEBE")
  expect_equal(cv$na_color, "#BEBEBE")
  expect_equal(as.numeric(cv$domain), c(0, 1))
})

test_that("infinite values get the end colors and do not set the default domain", {
  cv <- colorByValue(data.frame(resno = 1:4, value = c(-Inf, 0, 1, Inf)), palette = bwr)
  expect_equal(as.numeric(cv$domain), c(0, 1))
  expect_equal(as.character(cv$color), c("#0000FF", "#0000FF", "#FF0000", "#FF0000"))
})

test_that("a row for any chain does not clash with a chain named NA", {
  cv <- colorByValue(data.frame(chain = c(NA, "NA"), resno = c(5, 5), value = 1:2))
  expect_equal(as.character(cv$chain), c(NA, "NA"))
})

test_that("palette and domain are kept for a legend", {
  cv <- colorByValue(c("A:1" = 2, "A:2" = 4), palette = c("black", "yellow"))
  expect_equal(as.character(cv$palette), c("#000000", "#FFFF00"))
  expect_equal(as.numeric(cv$domain), c(2, 4))
})

test_that("a named vector gives chain, resno and insertion code", {
  cv <- colorByValue(c("A:12" = 1, "13" = 2, "B:5A" = 3, "AB:-2" = 4))
  expect_equal(as.character(cv$chain), c("A", NA, "B", "AB"))
  expect_equal(as.integer(cv$resno), c(12L, 13L, 5L, -2L))
  expect_equal(as.character(cv$inscode), c("", "", "A", ""))
  expect_true(all(is.na(cv$structure)))
})

test_that("a data frame may leave out chain, inscode and structure", {
  cv <- colorByValue(data.frame(resno = 1:2, value = 1:2))
  expect_true(all(is.na(cv$chain)))
  expect_equal(as.character(cv$inscode), c("", ""))
  expect_true(all(is.na(cv$structure)))
})

test_that("the _residues data frame with a value column works as is", {
  residues <- data.frame(structure = c(1L, 1L, 2L), chain = "A", resno = c(1L, 2L, 1L),
                         inscode = "", resname = "THR", letter = "T",
                         value = c(0, 1, 0.5))
  cv <- colorByValue(residues)
  expect_equal(as.integer(cv$structure), c(1L, 1L, 2L))
  expect_equal(as.character(cv$chain), c("A", "A", "A"))
  # The same residue in two structures is not a duplicate
  expect_length(cv$color, 3)
})

test_that("bad input gives clear errors", {
  df <- data.frame(resno = 1:2, value = 1:2)
  expect_error(colorByValue(data.frame(resno = 1:2)), "'value' column")
  expect_error(colorByValue(data.frame(value = 1:2)), "'resno' column")
  expect_error(colorByValue(data.frame(resno = 1:2, value = c("a", "b"))), "numeric")
  expect_error(colorByValue(data.frame(resno = c(1.5, 2), value = 1:2)), "whole numbers")
  expect_error(colorByValue(data.frame(resno = c(1, 1), value = 1:2)), "more than once.*1")
  expect_error(colorByValue(c("A:x" = 1)), "names")
  expect_error(colorByValue(c(1, 2)), "names")
  expect_error(colorByValue("A:1"), "data frame or a named numeric vector")
  expect_error(colorByValue(df[0, ]), "no rows")
  expect_error(colorByValue(df, palette = c("blue", "notacolor")), "palette")
  expect_error(colorByValue(df, palette = "blue"), "at least two")
  expect_error(colorByValue(df, palette = c(1, 2)), "palette")
  expect_error(colorByValue(df, na_color = "notacolor"), "na_color")
  expect_error(colorByValue(df, domain = c(1, 0)), "domain")
  expect_error(colorByValue(df, domain = 1), "domain")
  expect_error(colorByValue(data.frame(resno = 1, value = NA)), "domain")
  expect_error(colorByValue(cbind(df, structure = c(0, 1))), "structure")
})

test_that("the object reaches JSON as arrays, also for a single residue", {
  cv <- colorByValue(c("A:1" = 5))
  # The serializers of static widgets and of Shiny messages
  for (json in list(htmlwidgets:::toJSON(cv), shiny:::toJSON(cv))) {
    json <- as.character(json)
    expect_match(json, '"type":"values"', fixed = TRUE)
    expect_match(json, '"resno":[1]', fixed = TRUE)
    expect_match(json, '"chain":["A"]', fixed = TRUE)
    expect_match(json, '"structure":[null]', fixed = TRUE)
    expect_match(json, '"color":["#FFFFFF"]', fixed = TRUE)
    expect_match(json, '"na_color":"#BEBEBE"', fixed = TRUE)
  }
})

test_that("colorByValue() can be used as color in builders and proxy functions", {
  cv <- colorByValue(c("A:1" = 5))
  x <- (NGLVieweR("1CRN") %>% addRepresentation("cartoon", param = list(color = cv)))$x
  expect_identical(x$structures[[1]]$addRepresentation$values[[1]]$color, cv)

  p <- fake_proxy()
  updateColor(p, "cartoon", cv)
  expect_identical(last_msg(p)$message$color, cv)
})
