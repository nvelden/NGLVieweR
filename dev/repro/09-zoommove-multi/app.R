pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #9: zoomMove() is overridden when there are several structures.
# Launch from the project root:
#   shiny::runApp("dev/repro/09-zoommove-multi", launch.browser = TRUE)
#
# 1crn.pdb (red) and 1crn_moved2.pdb (green) are the same protein about
# 45 A apart. zoomMove(center = "1-5", zoom = "1-5") should end with the
# camera on residues 1-5 of the chosen structure.

fixtures <- normalizePath("../../../tests/testthat/fixtures")
files <- file.path(fixtures, c("1crn.pdb", "1crn_moved2.pdb"))

camera_js <- HTML("
$(document).on('shiny:connected', function() {
  setInterval(function() {
    var w = HTMLWidgets.find('#viewer');
    if (!w || !w.getStructure()) return;
    var comps = w.getStructure();
    var target = Number($('input[name=target]:checked').val()) - 1;
    if (target >= comps.length) return;
    var c = comps[target].getCenter('1-5');
    var p = w.getStage().viewerControls.position;
    var cam = [-p.x, -p.y, -p.z];
    var d = Math.sqrt(Math.pow(cam[0]-c.x,2) + Math.pow(cam[1]-c.y,2) + Math.pow(cam[2]-c.z,2));
    Shiny.setInputValue('camera', { distance: d,
      camera: cam.map(function(v) { return v.toFixed(1); }).join(', '),
      expected: [c.x, c.y, c.z].map(function(v) { return v.toFixed(1); }).join(', ') });
  }, 300);
});
")

ui <- fluidPage(
  tags$head(tags$script(camera_js)),
  titlePanel("Bug #9: zoomMove() is overridden with several structures"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Red = structure 1, green = structure 2. zoomMove() should center the camera on residues 1-5 ",
           "of the chosen structure ('distance' about 0). Wait ~2 s after each change for animations."),
    tags$ol(
      tags$li("1 structure: works (distance 0)."),
      tags$li("2 structures, duration 0: the camera ends on the middle of both structures instead."),
      tags$li("2 structures + superpose, zoomMove on structure 2: the camera goes to where structure 2 ",
              "was BEFORE superpose moved it.")
    )
  ),
  fluidRow(
    column(4,
      radioButtons("n", "Number of structures", c(1, 2), selected = 2, inline = TRUE),
      radioButtons("target", "zoomMove() on structure", c(1, 2), inline = TRUE),
      radioButtons("duration", "duration (ms)", c(0, 1000), inline = TRUE),
      checkboxInput("superpose", "setSuperpose(reference = 1)", FALSE),
      h4("Camera (2 s after render)"),
      verbatimTextOutput("camera")
    ),
    column(8, NGLVieweROutput("viewer", height = "500px"))
  )
)

server <- function(input, output, session) {
  output$viewer <- renderNGLVieweR({
    n <- as.integer(input$n)
    target <- as.integer(input$target)
    validate(need(target <= n, "zoomMove target must be <= number of structures"))
    zm <- function(w) zoomMove(w, center = "1-5", zoom = "1-5",
                               duration = as.numeric(input$duration))
    w <- NGLVieweR(files[1]) %>% addRepresentation("cartoon", param = list(color = "red"))
    if (target == 1) w <- zm(w)
    if (n == 2) {
      w <- w %>% addStructure(files[2]) %>%
        addRepresentation("cartoon", param = list(color = "green"))
      if (target == 2) w <- zm(w)
      if (input$superpose) {
        w <- w %>% setSuperpose(reference = 1, sele_reference = "1-46", sele_target = "1-46")
      }
    }
    w
  })
  output$camera <- renderText({
    d <- input$camera
    req(d)
    paste0("expected center: ", d$expected, "\ncamera center:   ", d$camera,
           "\ndistance:        ", round(d$distance, 1), " A",
           if (d$distance < 1) "   OK" else "   WRONG")
  })
}

shinyApp(ui, server)
