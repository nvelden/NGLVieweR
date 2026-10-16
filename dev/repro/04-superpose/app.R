pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #4: setSuperpose() moves the wrong structure.
# Launch from the project root:
#   shiny::runApp("dev/repro/04-superpose", launch.browser = TRUE)
#
# The three files are the same crambin structure: 1crn.pdb as deposited,
# and two copies moved by a known rotation + translation (see
# dev/make-fixtures.R). A correct superpose brings every copy exactly onto
# the reference (CA RMSD ~ 0) and leaves the reference where it was.

fixtures <- normalizePath("../../../tests/testthat/fixtures")
files <- file.path(fixtures, c("1crn.pdb", "1crn_moved.pdb", "1crn_moved2.pdb"))
colors <- c("red", "green", "blue")

# First CA coordinate of each file as loaded, to tell whether it moved.
first_ca <- lapply(files, function(f) {
  l <- readLines(f)
  l <- l[grepl("^ATOM", l) & substr(l, 13, 16) == " CA "][1]
  as.numeric(c(substr(l, 31, 38), substr(l, 39, 46), substr(l, 47, 54)))
})

debug_js <- HTML(sprintf("
var fileFirstCA = %s;
function caCoords(comp) {
  var xyz = [];
  comp.structure.eachAtom(function(a) { if (a.atomname === 'CA') xyz.push([a.x, a.y, a.z]); });
  return xyz;
}
function rmsd(a, b) {
  var s = 0;
  for (var i = 0; i < a.length; i++) {
    s += Math.pow(a[i][0]-b[i][0],2) + Math.pow(a[i][1]-b[i][1],2) + Math.pow(a[i][2]-b[i][2],2);
  }
  return Math.sqrt(s / a.length);
}
$(document).on('shiny:connected', function() {
  setInterval(function() {
    var w = HTMLWidgets.find('#viewer');
    if (!w || !w.getStructure()) return;
    var comps = w.getStructure();
    var ref = Number($('input[name=reference]:checked').val()) - 1;
    if (ref >= comps.length) return;
    var refCA = caCoords(comps[ref]);
    var rows = comps.map(function(c, i) {
      var ca = caCoords(c);
      var f = fileFirstCA[i];
      var moved = Math.sqrt(Math.pow(ca[0][0]-f[0],2) + Math.pow(ca[0][1]-f[1],2) + Math.pow(ca[0][2]-f[2],2));
      return { structure: i + 1, rmsdToRef: rmsd(ca, refCA), movedFromFile: moved };
    });
    Shiny.setInputValue('debug', {
      structure: rows.map(function(r) { return r.structure; }),
      rmsdToRef: rows.map(function(r) { return r.rmsdToRef; }),
      movedFromFile: rows.map(function(r) { return r.movedFromFile; })
    });
  }, 500);
});
", jsonlite::toJSON(first_ca)))

ui <- fluidPage(
  tags$head(tags$script(debug_js)),
  titlePanel("Bug #4: setSuperpose() moves the wrong structure"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Colors: structure 1 = red (1crn.pdb), 2 = green (moved copy), 3 = blue (second moved copy)."),
    tags$ol(
      tags$li("2 structures, reference 1: the overlay looks fine, but the debug panel shows ",
              "that the REFERENCE (1) moved ('moved from file' > 0) and the target (2) did not."),
      tags$li("3 structures, reference 1: structure 2 is NOT on the reference ",
              "(RMSD to reference >> 0). Only the last structure ends up aligned."),
      tags$li("3 structures, reference 2: now structure 1 (red) is the one left behind, ",
              "and the reference (green) moved.")
    ),
    tags$p("Correct behaviour: the reference does not move (0.00) and every structure has RMSD to reference ~ 0.00.")
  ),
  fluidRow(
    column(4,
      radioButtons("n", "Number of structures", c(2, 3), inline = TRUE),
      radioButtons("reference", "setSuperpose(reference =)", c(1, 2, 3), inline = TRUE),
      h4("Debug panel (from the structure coordinates)"),
      tableOutput("debug")
    ),
    column(8, NGLVieweROutput("viewer", height = "550px"))
  )
)

server <- function(input, output, session) {
  output$viewer <- renderNGLVieweR({
    n <- as.integer(input$n)
    ref <- as.integer(input$reference)
    validate(need(ref <= n, "reference must be <= number of structures"))
    w <- NGLVieweR(files[1]) %>%
      addRepresentation("cartoon", param = list(color = colors[1]))
    for (i in seq_len(n)[-1]) {
      w <- w %>% addStructure(files[i]) %>%
        addRepresentation("cartoon", param = list(color = colors[i]))
    }
    w %>% setSuperpose(reference = ref, sele_reference = "1-46", sele_target = "1-46")
  })

  output$debug <- renderTable({
    d <- input$debug
    req(d)
    structure <- as.integer(unlist(d$structure))
    data.frame(
      structure = structure,
      color = colors[structure],
      `RMSD to reference (A)` = unlist(d$rmsdToRef),
      `moved from file (A)` = unlist(d$movedFromFile),
      check.names = FALSE
    )
  }, digits = 2)
}

shinyApp(ui, server)
