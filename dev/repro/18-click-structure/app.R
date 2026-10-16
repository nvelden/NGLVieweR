pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for #18: a click does not say which structure was clicked.
# Launch from the project root:
#   shiny::runApp("dev/repro/18-click-structure", launch.browser = TRUE)
#
# A typical click-to-zoom app: clicking a residue zooms to it and highlights
# the residues around it. Two copies of crambin, about 45 A apart:
# structure 1 = red, structure 2 = green.

fixtures <- normalizePath("../../../tests/testthat/fixtures")

debug_js <- HTML("
// What was really clicked, and how far the camera ends from it.
$(document).on('shiny:connected', function() {
  var w0 = null;
  setInterval(function() {
    var w = HTMLWidgets.find('#viewer');
    if (!w || !w.getStructure()) return;
    if (w !== w0) {
      w0 = w;
      w.getStage().signals.clicked.add(function(pp) {
        if (!pp || !pp.atom) return;
        window.lastClick = { structure: w.getStructure().indexOf(pp.component) + 1,
                             atom: pp.atom.qualifiedName(), x: pp.atom.x, y: pp.atom.y, z: pp.atom.z };
      });
    }
    var c = window.lastClick;
    if (!c) return;
    var p = w.getStage().viewerControls.position;
    var d = Math.sqrt(Math.pow(-p.x - c.x, 2) + Math.pow(-p.y - c.y, 2) + Math.pow(-p.z - c.z, 2));
    Shiny.setInputValue('debug', { structure: c.structure, atom: c.atom, distance: d });
  }, 300);
});
// Simulates a click on residue 10 (CA) of the given structure.
function clickResidue(i) {
  var w = HTMLWidgets.find('#viewer');
  var comp = w.getStructure()[i - 1];
  var atom = comp.structure.getAtomProxy();
  comp.structure.eachAtom(function(a) { if (a.resno === 10 && a.atomname === 'CA') atom.index = a.index; });
  w.getStage().signals.clicked.dispatch({
    getLabel: function() { return 'atom: ' + atom.qualifiedName() + ' (' + comp.structure.name + ')'; },
    atom: atom, component: comp });
}
")

ui <- fluidPage(
  tags$head(tags$script(debug_js)),
  titlePanel("#18: a click does not say which structure was clicked"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Red = structure 1, green = structure 2. Click a residue on the GREEN structure ",
           "(or use the button). The app zooms to the clicked residue and highlights its surroundings."),
    tags$ol(
      tags$li("The camera goes to the same residue in the RED structure ('camera to clicked atom' is ~45 A)."),
      tags$li("The highlight (yellow ball+stick) appears on BOTH structures, at the clicked atom numbers."),
      tags$li("input$viewer_selection only has a label; there is no input that says which structure was clicked.")
    )
  ),
  fluidRow(
    column(4,
      tags$button("Click residue 10 of structure 2 (green)", onclick = "clickResidue(2)",
                  class = "btn btn-default"),
      tags$button("... of structure 1 (red)", onclick = "clickResidue(1)", class = "btn btn-default"),
      h4("What the app gets"),
      verbatimTextOutput("inputs"),
      h4("What really happened"),
      verbatimTextOutput("debug")
    ),
    column(8, NGLVieweROutput("viewer", height = "500px"))
  )
)

server <- function(input, output, session) {
  output$viewer <- renderNGLVieweR({
    NGLVieweR(file.path(fixtures, "1crn.pdb")) %>%
      addRepresentation("cartoon", param = list(color = "red")) %>%
      addStructure(file.path(fixtures, "1crn_moved2.pdb")) %>%
      addRepresentation("cartoon", param = list(color = "green"))
  })

  # The usual click-to-zoom code: residue from the label, then zoom and highlight.
  # With the fix, the app passes the clicked structure (input$viewer_selectionStructure,
  # NULL before the fix, which means "first" / "all").
  observeEvent(input$viewer_selection, {
    resi <- sub(".*\\]([0-9]+):([A-Z]).*", "\\1:\\2", input$viewer_selection)
    NGLVieweR_proxy("viewer") %>%
      updateZoomMove(center = resi, zoom = resi, duration = 0,
                     structure = input$viewer_selectionStructure)
  })
  observeEvent(input$viewer_selAround, {
    NGLVieweR_proxy("viewer") %>% removeSelection("around")
    NGLVieweR_proxy("viewer") %>%
      addSelection("ball+stick", param = list(name = "around", sele = input$viewer_selAround,
                                             color = "yellow"),
                   structure = input$viewer_selectionStructure)
  })

  output$inputs <- renderText(paste0(
    "input$viewer_selection: ", format(input$viewer_selection), "\n",
    "input$viewer_selAround: ", substr(format(input$viewer_selAround), 1, 40), "...\n",
    "input$viewer_selectionStructure: ", format(input$viewer_selectionStructure)
  ))
  output$debug <- renderText({
    d <- input$debug
    req(d)
    paste0("clicked: structure ", d$structure, ", ", d$atom, "\n",
           "camera to clicked atom: ", round(d$distance, 1), " A",
           if (d$distance < 3) "  OK" else "  WRONG (zoomed to the other structure)")
  })
}

shinyApp(ui, server)
