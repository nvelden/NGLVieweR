pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #27: input$<id>_PDB holds the coordinates from before
# setSuperpose(), not the superposed ones shown in the viewer.
# Launch from the project root:
#   shiny::runApp("dev/repro/27-pdb-superpose", launch.browser = TRUE)
#
# 1crn.pdb is the reference (stays put); 1crn_moved.pdb is the same
# structure moved by a known rotation + translation. After superpose the
# viewer shows the target on the reference, so the exported _PDB of the
# target should match the displayed coordinates (RMSD ~ 0).

fixtures <- normalizePath("../../../tests/testthat/fixtures")
files <- file.path(fixtures, c("1crn.pdb", "1crn_moved.pdb"))
colors <- c("red", "green")

# CA coordinates from PDB text.
pdb_ca <- function(pdb) {
  l <- strsplit(pdb, "\n", fixed = TRUE)[[1]]
  l <- l[grepl("^(ATOM|HETATM)", l) & substr(l, 13, 16) == " CA "]
  cbind(as.numeric(substr(l, 31, 38)), as.numeric(substr(l, 39, 46)),
        as.numeric(substr(l, 47, 54)))
}
rmsd <- function(a, b) {
  if (!identical(dim(a), dim(b))) return(NA_real_)
  sqrt(mean(rowSums((a - b)^2)))
}

# Sends the displayed CA coordinates of every structure every 500 ms.
debug_js <- HTML("
$(document).on('shiny:connected', function() {
  setInterval(function() {
    var w = HTMLWidgets.find('#viewer');
    if (!w || !w.getStructure()) return;
    var xyz = w.getStructure().map(function(c) {
      var s = [];
      c.structure.eachAtom(function(a) { if (a.atomname === 'CA') s.push(a.x, a.y, a.z); });
      return s;
    });
    Shiny.setInputValue('displayed', JSON.stringify(xyz));
  }, 500);
});
")

ui <- fluidPage(
  tags$head(tags$script(debug_js)),
  titlePanel("Bug #27: input$viewer_PDB is written before superposition"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Red = 1crn.pdb (reference), green = 1crn_moved.pdb (target). ",
           "In the viewer the green copy lies exactly on the red one."),
    tags$ol(
      tags$li("With superpose ON: the debug panel row for structure 2 shows a large ",
              "'RMSD exported vs displayed' (the exported target is still at its file position)."),
      tags$li("Download the exported PDBs and open them in another viewer: they do not overlay."),
      tags$li("With superpose OFF everything is 0.00 (nothing moved, so before = after).")
    ),
    tags$p("Correct behaviour: 'RMSD exported vs displayed' is ~0.00 for every structure.")
  ),
  fluidRow(
    column(4,
      checkboxInput("superpose", "setSuperpose()", TRUE),
      h4("Debug panel"),
      tableOutput("debug"),
      downloadButton("download", "Download exported _PDB (both, one file each, zip)")
    ),
    column(8, NGLVieweROutput("viewer", height = "550px"))
  )
)

server <- function(input, output, session) {
  output$viewer <- renderNGLVieweR({
    w <- NGLVieweR(files[1]) %>%
      addRepresentation("cartoon", param = list(color = colors[1])) %>%
      addStructure(files[2]) %>%
      addRepresentation("cartoon", param = list(color = colors[2]))
    if (input$superpose) {
      w <- w %>% setSuperpose(reference = 1, sele_reference = "1-46", sele_target = "1-46")
    }
    w
  })

  output$debug <- renderTable({
    req(input$viewer_PDB, input$displayed)
    pdb <- unlist(input$viewer_PDB)
    shown <- jsonlite::fromJSON(input$displayed, simplifyVector = FALSE)
    req(length(pdb) == length(shown))
    data.frame(
      structure = seq_along(pdb),
      color = colors[seq_along(pdb)],
      `RMSD exported vs displayed (A)` = vapply(seq_along(pdb), function(i) {
        rmsd(pdb_ca(pdb[i]), matrix(unlist(shown[[i]]), ncol = 3, byrow = TRUE))
      }, numeric(1)),
      `RMSD exported vs file (A)` = vapply(seq_along(pdb), function(i) {
        rmsd(pdb_ca(pdb[i]), pdb_ca(paste(readLines(files[i]), collapse = "\n")))
      }, numeric(1)),
      check.names = FALSE
    )
  }, digits = 2)

  output$download <- downloadHandler(
    filename = "exported_PDB.zip",
    content = function(file) {
      pdb <- unlist(input$viewer_PDB)
      dir <- tempfile(); dir.create(dir)
      paths <- file.path(dir, sprintf("structure%d.pdb", seq_along(pdb)))
      for (i in seq_along(pdb)) writeLines(pdb[i], paths[i])
      utils::zip(file, paths, flags = "-j")
    }
  )
}

shinyApp(ui, server)
