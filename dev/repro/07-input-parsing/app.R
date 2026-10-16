pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #7 (Step 6): input edge cases in .parse_structure_input().
# Launch from the project root:
#   shiny::runApp("dev/repro/07-input-parsing", launch.browser = TRUE)

pdb <- normalizePath("../../../tests/testthat/fixtures/1crn.pdb")
work <- file.path(tempdir(), "repro-07")
dir.create(work, showWarnings = FALSE)
gz <- file.path(work, "1crn.pdb.gz")
con <- gzfile(gz, "w"); writeLines(readLines(pdb), con); close(con)

# Each case: the R call, and the widget it builds (or the R error).
cases <- list(
  list(id = "a", title = "7a: mistyped file path",
       code = 'NGLVieweR("data/model.pdb")',
       make = function() NGLVieweR("data/model.pdb")),
  list(id = "b", title = "7b: readLines() lines",
       code = 'NGLVieweR(readLines("1crn.pdb"), format = "pdb")',
       make = function() NGLVieweR(readLines(pdb), format = "pdb")),
  list(id = "c", title = "7c: gzip-compressed file",
       code = 'NGLVieweR("1crn.pdb.gz")',
       make = function() NGLVieweR(gz)),
  list(id = "d", title = "Reference: plain file (works)",
       code = 'NGLVieweR("1crn.pdb")',
       make = function() NGLVieweR(pdb))
)

describe <- function(w) {
  if (inherits(w, "error")) return(paste("R error:", conditionMessage(w)))
  s <- w$x$structures[[1]]
  sprintf("type = %s, file_ext = %s, data = %s (%d element%s)",
          s$type, if (is.null(s$file_ext)) "NULL" else dQuote(s$file_ext, FALSE),
          dQuote(substr(s$data[1], 1, 30), FALSE), length(s$data),
          if (length(s$data) == 1) "" else "s")
}

status_js <- HTML("
$(document).on('shiny:connected', function() {
  setInterval(function() {
    ['a','b','c','d'].forEach(function(id) {
      var w = HTMLWidgets.find('#viewer_' + id);
      var s = w && w.getStructure();
      $('#status_' + id).text(s && s.length ? 'Loaded: ' + s[0].structure.atomCount + ' atoms' :
                              'Nothing loaded (see the browser console)');
    });
  }, 500);
});
")

ui <- fluidPage(
  tags$head(tags$script(status_js)),
  titlePanel("Bug #7: input edge cases"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Each panel shows the R call, the structure entry R built, and the viewer. ",
           "Today only the reference panel (bottom right) works; the others fail silently: no R error, ",
           "an empty viewer, and only a message in the browser console (open it with Cmd+Option+J).")
  ),
  fluidRow(lapply(cases[1:2], function(cs) column(6,
    h4(cs$title), tags$code(cs$code), tags$p(textOutput(paste0("desc_", cs$id))),
    actionButton(paste0("show_", cs$id), "Render this viewer (throws a JS error)"),
    tags$b(id = paste0("status_", cs$id)),
    NGLVieweROutput(paste0("viewer_", cs$id), height = "250px")))),
  fluidRow(lapply(cases[3:4], function(cs) column(6,
    h4(cs$title), tags$code(cs$code), tags$p(textOutput(paste0("desc_", cs$id))),
    tags$b(id = paste0("status_", cs$id)),
    NGLVieweROutput(paste0("viewer_", cs$id), height = "250px"))))
)

server <- function(input, output, session) {
  for (cs in cases) local({
    cs <- cs
    w <- tryCatch(cs$make(), error = function(e) e)
    output[[paste0("desc_", cs$id)]] <- renderText(describe(w))
    output[[paste0("viewer_", cs$id)]] <- renderNGLVieweR({
      # 7a and 7b throw a JS error that also breaks the other outputs
      # rendered in the same update, so they only render after their button.
      if (cs$id %in% c("a", "b")) req(input[[paste0("show_", cs$id)]])
      validate(need(!inherits(w, "error"), describe(w)))
      w %>% addRepresentation("cartoon")
    })
  })
}

shinyApp(ui, server)
