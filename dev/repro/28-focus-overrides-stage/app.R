pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #28: setFocus()/setQuality() defaults override clipping, fog
# and quality set with stageParameters(). Works offline (fixture file).
# Launch from the project root:
#   shiny::runApp("dev/repro/28-focus-overrides-stage", launch.browser = TRUE)

pdb <- normalizePath("../../../tests/testthat/fixtures/1crn.pdb")
keys <- c("clipNear", "clipFar", "fogNear", "fogFar", "quality", "clipMode", "clipScale")

# Sends NGL's actual stage parameters every 500 ms.
debug_js <- HTML(sprintf("
$(document).on('shiny:connected', function() {
  setInterval(function() {
    var w = HTMLWidgets.find('#viewer');
    if (!w || !w.getStage()) return;
    var p = w.getStage().parameters, out = {};
    %s.forEach(function(k) { out[k] = String(p[k]); });
    Shiny.setInputValue('actual', out);
  }, 500);
});
", jsonlite::toJSON(keys)))

# A slider with a checkbox: the value is only passed when ticked.
param_slider <- function(id, label, value, min = 0, max = 100) {
  tagList(
    checkboxInput(paste0("use_", id), tags$b(label), FALSE),
    sliderInput(id, NULL, min = min, max = max, value = value, step = 1)
  )
}

ui <- fluidPage(
  tags$head(tags$script(debug_js)),
  titlePanel("Bug #28: stageParameters() clipping, fog and quality"),
  wellPanel(
    tags$b("What to try"),
    tags$ol(
      tags$li("Tick an option to pass it to stageParameters(), then move its slider. ",
              "Every change re-renders the viewer, as renderNGLVieweR() would."),
      tags$li("clipNear: from about 40 the front of the protein is cut away. ",
              "clipFar: below about 60 the back disappears."),
      tags$li("fogNear / fogFar: low values hide the protein in the (black) fog; ",
              "fogNear must be below fogFar to see a gradient."),
      tags$li("Tick setFocus(): it sets all four clip/fog values at once. Then tick a ",
              "single option such as fogFar: that one wins, the rest keeps the focus values."),
      tags$li("Untick everything: the viewer returns to NGL's defaults (0 / 100 / 50 / 100, medium).")
    ),
    tags$p("The table shows what was passed and NGL's actual stage parameters. ",
           "Before the fix 'actual' stayed at the defaults whatever you set.")
  ),
  fluidRow(
    column(3,
      h4("stageParameters()"),
      param_slider("clipNear", "clipNear", 40),
      param_slider("clipFar", "clipFar", 60),
      param_slider("fogNear", "fogNear", 20),
      param_slider("fogFar", "fogFar", 40),
      checkboxInput("use_quality", tags$b("quality"), FALSE),
      radioButtons("quality", NULL, c("low", "medium", "high"), "high", inline = TRUE),
      checkboxInput("use_clipMode", tags$b("clipMode"), FALSE),
      radioButtons("clipMode", NULL, c("scene", "camera"), "camera", inline = TRUE),
      h4("Shortcuts"),
      checkboxInput("use_focus", tags$b("setFocus()"), FALSE),
      sliderInput("focus", NULL, min = 0, max = 100, value = 50, step = 1),
      checkboxInput("use_setQuality", tags$b("setQuality()"), FALSE),
      radioButtons("setQuality", NULL, c("low", "medium", "high"), "low", inline = TRUE)
    ),
    column(6, NGLVieweROutput("viewer", height = "600px")),
    column(3,
      h4("R code of this render"),
      verbatimTextOutput("code"),
      h4("Stage parameters"),
      tableOutput("debug")
    )
  )
)

server <- function(input, output, session) {
  passed <- reactive({
    p <- list()
    for (k in c("clipNear", "clipFar", "fogNear", "fogFar", "quality", "clipMode")) {
      if (isTRUE(input[[paste0("use_", k)]])) p[[k]] <- input[[k]]
    }
    p
  })

  output$viewer <- renderNGLVieweR({
    w <- NGLVieweR(pdb) %>%
      addRepresentation("cartoon", param = list(colorScheme = "residueindex")) %>%
      addRepresentation("ball+stick")
    if (input$use_focus) w <- setFocus(w, input$focus)
    if (input$use_setQuality) w <- setQuality(w, input$setQuality)
    do.call(stageParameters, c(list(w), passed()))
  })

  output$code <- renderText({
    p <- passed()
    args <- vapply(names(p), function(k) {
      v <- p[[k]]
      paste0(k, " = ", if (is.character(v)) dQuote(v, FALSE) else v)
    }, character(1))
    paste(c(
      "NGLVieweR(\"1crn.pdb\") %>%",
      "  addRepresentation(...) %>%",
      if (input$use_focus) paste0("  setFocus(", input$focus, ") %>%"),
      if (input$use_setQuality) paste0("  setQuality(\"", input$setQuality, "\") %>%"),
      paste0("  stageParameters(", paste(args, collapse = ", "), ")")
    ), collapse = "\n")
  })

  output$debug <- renderTable({
    req(input$actual)
    p <- passed()
    data.frame(
      parameter = keys,
      passed = vapply(keys, function(k) {
        if (is.null(p[[k]])) "" else as.character(p[[k]])
      }, character(1)),
      actual = vapply(keys, function(k) {
        v <- input$actual[[k]]
        n <- suppressWarnings(as.numeric(v))
        if (is.na(n)) v else format(round(n, 1))
      }, character(1))
    )
  })
}

shinyApp(ui, server)
