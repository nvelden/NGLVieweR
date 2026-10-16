expect_sent <- function(proxy, type, message) {
  m <- last_msg(proxy)
  expect_equal(m$type, paste0("NGLVieweR:", type))
  expect_equal(m$message, c(list(id = "viewer"), message))
}

test_that("proxy functions return the proxy and send one message each", {
  p <- fake_proxy()
  out <- p %>%
    updateFocus(10) %>%
    updateRock(FALSE) %>%
    updateSpin(FALSE)
  expect_identical(out, p)
  expect_length(p$sent$msgs, 3)
})

test_that("addSelection()", {
  p <- fake_proxy()
  addSelection(p, "ball+stick", param = list(name = "sel1", sele = "1-20"))
  expect_sent(p, "addSelection",
              list(type = "ball+stick", param = list(name = "sel1", sele = "1-20")))
})

test_that("removeSelection()", {
  p <- fake_proxy()
  removeSelection(p, "sel1")
  expect_sent(p, "removeSelection", list(name = "sel1"))
})

test_that("updateSelection()", {
  p <- fake_proxy()
  updateSelection(p, "sel1", sele = "1-10")
  expect_sent(p, "updateSelection", list(name = "sel1", sele = "1-10"))
})

test_that("updateColor()", {
  p <- fake_proxy()
  updateColor(p, "sel1", "red")
  expect_sent(p, "updateColor", list(name = "sel1", color = "red"))
})

test_that("snapShot()", {
  p <- fake_proxy()
  snapShot(p)
  expect_sent(p, "snapShot", list(fileName = "Snapshot", param = list()))
  snapShot(p, "img", param = list(factor = 2))
  expect_sent(p, "snapShot", list(fileName = "img", param = list(factor = 2)))
})

test_that("updateVisibility()", {
  p <- fake_proxy()
  updateVisibility(p, "sel1")
  expect_sent(p, "updateVisibility", list(name = "sel1", value = FALSE))
})

test_that("updateRepresentation()", {
  p <- fake_proxy()
  updateRepresentation(p, "sel1", param = list(opacity = 0.5))
  expect_sent(p, "updateRepresentation", list(name = "sel1", param = list(opacity = 0.5)))
})

test_that("updateStage()", {
  p <- fake_proxy()
  updateStage(p, param = list(backgroundColor = "white"))
  expect_sent(p, "updateStage", list(param = list(backgroundColor = "white")))
})

test_that("updateFocus()", {
  p <- fake_proxy()
  updateFocus(p)
  expect_sent(p, "updateFocus", list(focus = 0))
})

test_that("updateRock() and updateSpin()", {
  p <- fake_proxy()
  updateRock(p)
  expect_sent(p, "updateRock", list(rock = TRUE))
  updateSpin(p, FALSE)
  expect_sent(p, "updateSpin", list(spin = FALSE))
})

test_that("updateFullscreen() sends the requested value and element", {
  p <- fake_proxy()
  updateFullscreen(p)
  expect_sent(p, "updateFullscreen", list(fullscreen = TRUE, element = "page"))
  updateFullscreen(p, FALSE)
  expect_sent(p, "updateFullscreen", list(fullscreen = FALSE, element = "page"))
  updateFullscreen(p, TRUE, element = "viewer")
  expect_sent(p, "updateFullscreen", list(fullscreen = TRUE, element = "viewer"))
  updateFullscreen(p, TRUE, element = c("page", "viewer"))
  expect_sent(p, "updateFullscreen", list(fullscreen = TRUE, element = "page"))
})

test_that("updateFullscreen() validates its arguments", {
  p <- fake_proxy()
  expect_error(updateFullscreen(p, element = "window"), "element")
  expect_error(updateFullscreen(p, fullscreen = NA), "fullscreen")
  expect_error(updateFullscreen(p, fullscreen = "yes"), "fullscreen")
  expect_length(p$sent$msgs, 0)
})

test_that("updateZoomMove()", {
  p <- fake_proxy()
  updateZoomMove(p, center = "1-5", zoom = "1-5")
  expect_sent(p, "updateZoomMove",
              list(center = "1-5", zoom = "1-5", duration = 0, z_offSet = 0))
  updateZoomMove(p, center = "1", zoom = "2", duration = 100, z_offSet = 5,
                 structureIndex = 1)
  expect_sent(p, "updateZoomMove",
              list(center = "1", zoom = "2", duration = 100, z_offSet = 5,
                   structureIndex = 1))
})

test_that("NGLVieweR_proxy() requires a session and namespaces the id", {
  expect_error(NGLVieweR_proxy("viewer", session = NULL), "server function")
  session <- list(ns = shiny::NS("mod"))
  expect_equal(NGLVieweR_proxy("viewer", session = session)$id, "mod-viewer")
  expect_equal(NGLVieweR_proxy("mod-viewer", session = session)$id, "mod-viewer")
})
