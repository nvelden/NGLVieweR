two_structures <- function() NGLVieweR("1CRN") %>% addStructure("7CID")

test_that("addRepresentation() appends type and params to the last structure", {
  x <- (two_structures() %>%
    addRepresentation("cartoon", param = list(color = "red")) %>%
    addRepresentation("ball+stick"))$x
  expect_equal(x$structures[[1]]$addRepresentation, list(type = list(), values = list()))
  rep <- x$structures[[2]]$addRepresentation
  expect_equal(rep$type, list("cartoon", "ball+stick"))
  expect_equal(rep$values, list(list(color = "red"), list()))
})

test_that("per-structure builders target the last structure", {
  x <- (two_structures() %>%
    setScale(2) %>%
    setPosition(1, 2, 3) %>%
    zoomMove(center = "1-5", zoom = "1-5", duration = 500, z_offSet = -10))$x
  first <- x$structures[[1]]
  last <- x$structures[[2]]
  expect_equal(first$setScale, 1)
  expect_equal(first$setPosition, list())
  expect_equal(first$zoomMove, list())
  expect_equal(last$setScale, 2)
  expect_equal(last$setPosition, list(x = 1, y = 2, z = 3))
  expect_equal(last$zoomMove,
               list(center = "1-5", zoom = "1-5", duration = 500, z_offSet = -10))
})

test_that("setRotation() converts degrees to radians unless degrees = FALSE", {
  x <- (NGLVieweR("1CRN") %>% setRotation(90, 180, 0))$x
  expect_equal(x$structures[[1]]$setRotation, list(x = pi / 2, y = pi, z = 0))
  x <- (NGLVieweR("1CRN") %>% setRotation(1, 2, 3, degrees = FALSE))$x
  expect_equal(x$structures[[1]]$setRotation, list(x = 1, y = 2, z = 3))
})

test_that("stage-wide builders set top-level fields", {
  x <- (NGLVieweR("1CRN") %>%
    stageParameters(backgroundColor = "black", zoomSpeed = 1) %>%
    selectionParameters(proximity = 5, level = "atom") %>%
    setQuality("high") %>%
    setFocus(50) %>%
    setRock() %>%
    setSpin())$x
  expect_equal(x$stageParameters, list(backgroundColor = "black", zoomSpeed = 1))
  expect_equal(x$selectionParameters, list(proximity = 5, level = "atom"))
  expect_equal(x$setQuality, "high")
  expect_equal(x$setFocus, 50)
  expect_true(x$setRock)
  expect_true(x$setSpin)
})

test_that("selectionParameters() defaults", {
  x <- (NGLVieweR("1CRN") %>% selectionParameters())$x
  expect_equal(x$selectionParameters, list(proximity = 3, level = "residue"))
})

test_that("setSuperpose() stores its arguments", {
  x <- (two_structures() %>%
    setSuperpose(reference = 2, sele_reference = ":A", sele_target = ":B"))$x
  expect_equal(x$superpose, list(superpose = TRUE, reference = 2,
                                 seleReference = ":A", seleTarget = ":B"))
})

test_that("setSuperpose() rejects an invalid reference", {
  for (bad in list(0, -1, 1.5, NA, Inf, "1", c(1, 2))) {
    expect_error(two_structures() %>%
                   setSuperpose(reference = bad, sele_reference = ":A", sele_target = ":A"),
                 "reference", info = deparse(bad))
  }
  expect_no_error(two_structures() %>%
                    setSuperpose(reference = 2L, sele_reference = ":A", sele_target = ":A"))
})

test_that("setSuperpose() requires both selections", {
  expect_error(two_structures() %>% setSuperpose(sele_reference = ":A"),
               "'sele_reference' and 'sele_target' parameters are mandatory")
  expect_error(two_structures() %>% setSuperpose(sele_target = ":A"),
               "'sele_reference' and 'sele_target' parameters are mandatory")
})
