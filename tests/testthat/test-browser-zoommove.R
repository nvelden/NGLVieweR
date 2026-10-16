# Bug #9: zoomMove() must end with the camera on the requested selection,
# also with several structures and after superpose. 1crn.pdb and
# 1crn_moved2.pdb are the same protein about 45 A apart.

zoommove_app <- function(target, duration, superpose = FALSE, both = FALSE,
                         env = parent.frame()) {
  make_app(c(
    "files <- file.path(fixture_dir, c('1crn.pdb', '1crn_moved2.pdb'))",
    sprintf("target <- %d; duration <- %d; superpose <- %s; both <- %s",
            target, duration, superpose, both),
    "zm <- function(w) zoomMove(w, center = '1-5', zoom = '1-5', duration = duration)",
    "ui <- fluidPage(NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    w <- NGLVieweR(files[1]) %>% addRepresentation('cartoon')",
    "    if (target == 1 || both) w <- zm(w)",
    "    w <- w %>% addStructure(files[2]) %>% addRepresentation('cartoon')",
    "    if (target == 2 || both) w <- zm(w)",
    "    if (superpose) w <- w %>% setSuperpose(reference = 1, sele_reference = '1-46', sele_target = '1-46')",
    "    w",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# JS expression: distance (A) between the camera center and residues 1-5
# of structure `target`.
distance_js <- function(target) sprintf("(function(){
    var w = HTMLWidgets.find('#viewer'); var stage = w.getStage();
    var c = w.getStructure()[%d].getCenter('1-5');
    var p = stage.viewerControls.position;
    return Math.sqrt(Math.pow(-p.x - c.x, 2) + Math.pow(-p.y - c.y, 2) + Math.pow(-p.z - c.z, 2));
  })()", target - 1)

# JS expression: difference between the camera distance and the zoom NGL
# computes for residues 1-5 of structure `target` (0 when the zoom is right).
zoom_error_js <- function(target) sprintf("(function(){
    var w = HTMLWidgets.find('#viewer'); var stage = w.getStage();
    var z = w.getStructure()[%d].getZoom('1-5');
    return Math.abs(stage.viewer.camera.position.z - z);
  })()", target - 1)

# Waits (up to 10 s) until the camera has arrived at both the center and the
# zoom, so animations do not make the tests timing-dependent.
wait_for_camera <- function(app, target) {
  app$wait_for_value(input = "viewer_PDB", ignore = list(NULL))
  try(app$wait_for_js(paste(distance_js(target), "< 1 &&", zoom_error_js(target), "< 1"),
                      timeout = 10000), silent = TRUE)
}

camera_distance <- function(app, target) {
  wait_for_camera(app, target)
  app$get_js(distance_js(target))
}

zoom_error <- function(app, target) {
  wait_for_camera(app, target)
  app$get_js(zoom_error_js(target))
}

for (target in 1:2) for (duration in c(0, 1000)) {
  test_that(sprintf("zoomMove on structure %d of 2, duration %d", target, duration), {
    skip_if_no_browser()
    app <- start_app(zoommove_app(target, duration))
    expect_lt(camera_distance(app, target), 1)
    expect_lt(zoom_error(app, target), 1)
  })
}

for (duration in c(0, 1000)) {
  test_that(sprintf("zoomMove on a superposed target, duration %d", duration), {
    skip_if_no_browser()
    app <- start_app(zoommove_app(2, duration, superpose = TRUE))
    expect_lt(camera_distance(app, 2), 1)
  })
}

test_that("zoomMove() warns when an earlier structure has one too", {
  w <- NGLVieweR("1CRN") %>% zoomMove("1-5", "1-5")
  expect_no_warning(w %>% zoomMove("1-10", "1-10"))
  w2 <- w %>% addStructure("7CID")
  expect_no_warning(w2)
  expect_warning(w2 %>% zoomMove("1-5", "1-5"), "only the last one is used")
})

test_that("zoomMove on both structures: the last one is used", {
  skip_if_no_browser()
  app <- suppressWarnings(start_app(zoommove_app(2, 0, both = TRUE)))
  expect_lt(camera_distance(app, 2), 1)
})
