# #18 / #12: a click reports which structure was clicked (1-based), and
# addSelection()/updateZoomMove() target a structure by that number.
# 1crn.pdb and 1crn_moved2.pdb are the same protein about 45 A apart.

click_app <- function(env = parent.frame()) {
  make_app(c(
    "files <- file.path(fixture_dir, c('1crn.pdb', '1crn_moved2.pdb'))",
    "ui <- fluidPage(NGLVieweROutput('viewer'))",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    NGLVieweR(files[1]) %>% addRepresentation('cartoon') %>%",
    "      addStructure(files[2]) %>% addRepresentation('cartoon')",
    "  })",
    "  # Click-to-zoom and highlight, using the clicked structure.",
    "  observeEvent(input$viewer_selection, {",
    "    resi <- sub('.*\\\\]([0-9]+):([A-Z]).*', '\\\\1:\\\\2', input$viewer_selection)",
    "    NGLVieweR_proxy('viewer') %>%",
    "      updateZoomMove(center = resi, zoom = resi, structure = input$viewer_selectionStructure)",
    "  })",
    "  observeEvent(input$viewer_selAround, {",
    "    NGLVieweR_proxy('viewer') %>%",
    "      addSelection('ball+stick', param = list(name = 'around', sele = input$viewer_selAround),",
    "                   structure = input$viewer_selectionStructure)",
    "  })",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# Dispatches a click on residue 10 (CA) of structure `i` (1-based).
click_residue <- function(app, i) {
  app$run_js(sprintf("
    var w = HTMLWidgets.find('#viewer');
    var comp = w.getStructure()[%d];
    var atom = comp.structure.getAtomProxy();
    comp.structure.eachAtom(function(a) { if (a.resno === 10 && a.atomname === 'CA') atom.index = a.index; });
    window.__clicked = [atom.x, atom.y, atom.z];
    w.getStage().signals.clicked.dispatch({
      getLabel: function() { return 'atom: ' + atom.qualifiedName() + ' ()'; },
      atom: atom, component: comp });", i - 1))
}

camera_to_click_js <- "(function(){
  var p = HTMLWidgets.find('#viewer').getStage().viewerControls.position, c = window.__clicked;
  return Math.sqrt(Math.pow(-p.x - c[0], 2) + Math.pow(-p.y - c[1], 2) + Math.pow(-p.z - c[2], 2));
})()"

# Structures (1-based) that have the 'around' highlight.
highlighted <- function(app) {
  unlist(app$get_js("HTMLWidgets.find('#viewer').getStructure().map(function(c, i) {
    return c.reprList.some(function(r) { return r.name === 'around'; }) ? i + 1 : null;
  }).filter(function(x) { return x !== null; })"))
}

for (i in 1:2) {
  test_that(sprintf("a click on structure %d reports %d, zooms and highlights there", i, i), {
    skip_if_no_browser()
    app <- start_app(click_app())
    click_residue(app, i)
    app$wait_for_value(input = "viewer_selectionStructure", ignore = list(NULL))
    expect_equal(app$get_value(input = "viewer_selectionStructure"), i)
    try(app$wait_for_js(paste(camera_to_click_js, "< 3"), timeout = 5000), silent = TRUE)
    expect_lt(app$get_js(camera_to_click_js), 3)
    app$wait_for_js("HTMLWidgets.find('#viewer').getStructure().some(function(c) {
      return c.reprList.some(function(r) { return r.name === 'around'; }); })", timeout = 5000)
    expect_equal(highlighted(app), i)
    expect_equal(console_errors(app), character())
  })
}

test_that("clicking the same residue in the other structure acts on that structure", {
  skip_if_no_browser()
  app <- start_app(click_app())
  click_residue(app, 2)
  app$wait_for_value(input = "viewer_selectionStructure", ignore = list(NULL))
  try(app$wait_for_js(paste(camera_to_click_js, "< 3"), timeout = 5000), silent = TRUE)
  # Same residue, same label and same atom numbers, in structure 1
  click_residue(app, 1)
  app$wait_for_js("Shiny.shinyapp.$inputValues['viewer_selectionStructure:shiny.event'] === 1 ||
                   Shiny.shinyapp.$inputValues['viewer_selectionStructure'] === 1", timeout = 5000)
  try(app$wait_for_js(paste(camera_to_click_js, "< 3"), timeout = 5000), silent = TRUE)
  expect_lt(app$get_js(camera_to_click_js), 3)
  app$wait_for_js("HTMLWidgets.find('#viewer').getStructure()[0].reprList.some(function(r) {
    return r.name === 'around'; })", timeout = 5000)
  expect_true(1 %in% highlighted(app))
})
