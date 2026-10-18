# F1: colorByValue() colors residues by values from R, through a custom NGL
# color scheme. 1crn.pdb and 1crn_moved2.pdb are the same protein (chain A,
# residues 1-46).

color_app <- function(env = parent.frame()) {
  make_app(c(
    "files <- file.path(fixture_dir, c('1crn.pdb', '1crn_moved2.pdb'))",
    "map <- function(values, ...) colorByValue(data.frame(chain = 'A', resno = 1:46,",
    "                                                     value = values), ...)",
    "ui <- fluidPage(",
    "  selectInput('palette', 'palette', c('bwr', 'gray')),",
    "  actionButton('update', 'update'), actionButton('select', 'select'),",
    "  actionButton('rep', 'rep'), actionButton('perStructure', 'perStructure'),",
    "  actionButton('race', 'race'), actionButton('selColor', 'selColor'),",
    "  NGLVieweROutput('viewer')",
    ")",
    "server <- function(input, output) {",
    "  output$viewer <- renderNGLVieweR({",
    "    palette <- if (input$palette == 'bwr') c('blue', 'white', 'red') else c('black', 'white')",
    "    NGLVieweR(files[1]) %>%",
    "      addRepresentation('cartoon', param = list(name = 'cartoon',",
    "        color = map(c(0, rep(0.5, 44), 1), palette = palette, domain = c(0, 1)))) %>%",
    "      addRepresentation('ball+stick', param = list(name = 'sel', sele = '1-10',",
    "        color = list(c('green', '1-5'), c('yellow', '*')))) %>%",
    "      addStructure(files[2]) %>%",
    "      addRepresentation('cartoon', param = list(name = 'cartoon',",
    "        color = map(c(0, rep(0.5, 44), 1), palette = palette, domain = c(0, 1))))",
    "  })",
    "  proxy <- NGLVieweR_proxy('viewer')",
    "  # Residue 1 red, 46 blue, residue 2 not listed (na_color black)",
    "  observeEvent(input$update, updateColor(proxy, 'cartoon',",
    "    colorByValue(data.frame(resno = c(1, 3:46), value = c(1, rep(0.5, 43), 0)),",
    "                 domain = c(0, 1), na_color = 'black')))",
    "  observeEvent(input$select, addSelection(proxy, 'ball+stick',",
    "    param = list(name = 'added', sele = '1-3',",
    "                 color = colorByValue(c('A:1' = 1, 'A:2' = 0), palette = c('black', 'red'))),",
    "    structure = 2))",
    "  observeEvent(input$rep, updateRepresentation(proxy, 'cartoon',",
    "    param = list(color = colorByValue(c('1' = 0, '2' = 1), palette = c('green', 'blue')))))",
    "  # removeSelection() frees unused schemes while updateRepresentation() waits",
    "  observeEvent(input$race, {",
    "    updateRepresentation(proxy, 'cartoon',",
    "      param = list(color = colorByValue(c('1' = 0, '2' = 1), palette = c('green', 'blue'))))",
    "    removeSelection(proxy, 'nothing')",
    "  })",
    "  # A new selection scheme for the 'sel' representation each click",
    "  observeEvent(input$selColor, updateColor(proxy, 'sel',",
    "    list(c(sample(c('red', 'blue'), 1), '1-5'), c('white', '*'))))",
    "  # Structure 1 red, structure 2 blue, by the structure column",
    "  observeEvent(input$perStructure, updateColor(proxy, 'cartoon',",
    "    colorByValue(data.frame(structure = rep(1:2, each = 46), chain = 'A',",
    "                            resno = rep(1:46, 2), value = rep(c(1, 0), each = 46)))))",
    "}",
    "shinyApp(ui, server)"
  ), env = env)
}

# Hex color that the representation `name` of structure `i` (1-based) gives
# the CA atom of residue `resno`, computed by the representation's own color
# scheme with the parameters NGL passes when it builds the buffers (these
# contain a view of the structure, not the component's structure).
atom_color <- function(app, name, resno, i = 1) {
  app$get_js(sprintf("(function(){
    var comp = HTMLWidgets.find('#viewer').getStructure()[%d];
    var repr = comp.reprList.filter(function(r) { return r.name === '%s'; })[0];
    var cm = NGL.ColormakerRegistry.getScheme(repr.repr.getColorParams());
    var atom = comp.structure.getAtomProxy();
    comp.structure.eachAtom(function(a) {
      if (a.resno === %d && a.atomname === 'CA') atom.index = a.index; });
    return '#' + ('000000' + cm.atomColor(atom).toString(16)).slice(-6).toUpperCase();
  })()", i - 1, name, resno))
}

# Color scheme ids (colorByValue() schemes) currently in NGL's registry.
value_schemes <- function(app) {
  unlist(app$get_js("Object.keys(NGL.ColormakerRegistry.userSchemes)
    .filter(function(k) { return /\\|colorbyvalue$/.test(k); })"))
}

wait_color <- function(app, name, resno, expected, i = 1) {
  app$wait_for_js(sprintf("(function(){
    var comp = HTMLWidgets.find('#viewer').getStructure()[%d];
    var repr = comp.reprList.filter(function(r) { return r.name === '%s'; })[0];
    if (!repr) return false;
    var cm = NGL.ColormakerRegistry.getScheme(repr.repr.getColorParams());
    var atom = comp.structure.getAtomProxy();
    comp.structure.eachAtom(function(a) {
      if (a.resno === %d && a.atomname === 'CA') atom.index = a.index; });
    return cm.atomColor(atom) === parseInt('%s'.slice(1), 16);
  })()", i - 1, name, resno, expected), timeout = 10000)
}

test_that("addRepresentation() colors residues by value; selection schemes still work", {
  skip_if_no_browser()
  app <- start_app(color_app())
  for (i in 1:2) {
    expect_equal(atom_color(app, "cartoon", 1, i), "#0000FF")
    expect_equal(atom_color(app, "cartoon", 20, i), "#FFFFFF")
    expect_equal(atom_color(app, "cartoon", 46, i), "#FF0000")
  }
  expect_equal(atom_color(app, "sel", 3), "#008000")
  expect_equal(atom_color(app, "sel", 8), "#FFFF00")
  expect_length(value_schemes(app), 2)
  expect_length(console_errors(app), 0)
})

test_that("updateColor() applies a new map, na_color, and frees the old schemes", {
  skip_if_no_browser()
  app <- start_app(color_app())
  old <- value_schemes(app)
  app$click("update")
  wait_color(app, "cartoon", 1, "#FF0000")
  for (i in 1:2) {
    expect_equal(atom_color(app, "cartoon", 1, i), "#FF0000")
    expect_equal(atom_color(app, "cartoon", 2, i), "#000000")
    expect_equal(atom_color(app, "cartoon", 46, i), "#0000FF")
  }
  now <- value_schemes(app)
  expect_length(now, 1)
  expect_false(any(old %in% now))
  expect_length(console_errors(app), 0)
})

test_that("the structure column colors each structure separately", {
  skip_if_no_browser()
  app <- start_app(color_app())
  app$click("perStructure")
  wait_color(app, "cartoon", 10, "#FF0000", i = 1)
  expect_equal(atom_color(app, "cartoon", 10, 1), "#FF0000")
  expect_equal(atom_color(app, "cartoon", 10, 2), "#0000FF")
})

test_that("addSelection() and updateRepresentation() accept colorByValue()", {
  skip_if_no_browser()
  app <- start_app(color_app())
  app$click("select")
  wait_color(app, "added", 1, "#FF0000", i = 2)
  expect_equal(atom_color(app, "added", 2, 2), "#000000")
  # Residue 3 is not in the map: default na_color grey
  expect_equal(atom_color(app, "added", 3, 2), "#BEBEBE")

  app$click("rep")
  wait_color(app, "cartoon", 2, "#0000FF")
  expect_equal(atom_color(app, "cartoon", 1, 1), "#00FF00")
  expect_equal(atom_color(app, "cartoon", 2, 2), "#0000FF")
  # Two cartoons now share one scheme, plus the selection's scheme
  expect_length(value_schemes(app), 2)
  expect_length(console_errors(app), 0)
})

test_that("a scheme sent with updateRepresentation() is not freed before it is used", {
  skip_if_no_browser()
  app <- start_app(color_app())
  app$click("race")
  wait_color(app, "cartoon", 2, "#0000FF")
  expect_equal(atom_color(app, "cartoon", 1, 2), "#00FF00")
  expect_length(console_errors(app), 0)
})

# Number of user color schemes of any kind (value and selection schemes).
all_schemes <- function(app) {
  app$get_js("Object.keys(NGL.ColormakerRegistry.userSchemes).length")
}

test_that("selection color schemes are freed when no longer used", {
  skip_if_no_browser()
  app <- start_app(color_app())
  # 2 value schemes (one per cartoon) + 1 selection scheme
  expect_equal(all_schemes(app), 3)
  for (i in 1:3) {
    app$click("selColor")
    app$wait_for_js("Shiny.shinyapp.$inputValues['viewer_rendering'] === false", timeout = 10000)
  }
  Sys.sleep(0.5)
  expect_equal(all_schemes(app), 3)
  expect_equal(atom_color(app, "sel", 8), "#FFFFFF")
  rerender(app, palette = "gray")
  expect_equal(all_schemes(app), 3)
  expect_length(console_errors(app), 0)
})

test_that("re-rendering frees the schemes of the previous render", {
  skip_if_no_browser()
  app <- start_app(color_app())
  old <- value_schemes(app)
  rerender(app, palette = "gray")
  wait_color(app, "cartoon", 1, "#000000")
  now <- value_schemes(app)
  expect_length(now, 2)
  expect_false(any(old %in% now))
})

test_that("colorByValue() works in a static widget", {
  skip_if_no_browser()
  skip_if_not_installed("htmlwidgets")
  # Own folder: saveWidget() puts the JS in a lib/ folder next to the page
  html <- file.path(withr::local_tempdir(), "color.html")
  w <- NGLVieweR(fixture("1crn.pdb")) %>%
    addRepresentation("cartoon", param = list(name = "cartoon",
      color = colorByValue(c("A:1" = 1, "A:2" = 0), palette = c("blue", "red"))))
  htmlwidgets::saveWidget(w, html, selfcontained = FALSE)
  b <- chromote::ChromoteSession$new()
  withr::defer(b$close())
  b$Page$navigate(paste0("file://", normalizePath(html)))
  expr <- "(function(){ var w = HTMLWidgets.find('.NGLVieweR');
    var s = w && w.getStructure(); if (!s || !s.length || !s[0].reprList.length) return null;
    var comp = s[0], repr = comp.reprList[0];
    var cm = NGL.ColormakerRegistry.getScheme(repr.repr.getColorParams());
    var out = [];
    comp.structure.eachAtom(function(a) {
      if (a.atomname === 'CA' && a.resno <= 3) out.push(cm.atomColor(a)); });
    return out; })()"
  colors <- NULL
  for (k in 1:100) {
    colors <- b$Runtime$evaluate(expr, returnByValue = TRUE)$result$value
    if (length(colors)) break
    Sys.sleep(0.2)
  }
  expect_equal(unlist(colors), c(0xFF0000, 0x0000FF, 0xBEBEBE))
})
