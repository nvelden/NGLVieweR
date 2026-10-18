pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# F1 demo: colorByValue() colors residues by values computed in R.
# Launch from the project root:
#   shiny::runApp("dev/features/F01-color-by-values", launch.browser = TRUE)

fixtures <- normalizePath("../../../tests/testthat/fixtures")
files <- file.path(fixtures, c("1crn.pdb", "1crn_moved2.pdb"))

# Per-residue CA B-factors of 1crn, read in R: a real value to color by
pdb <- readLines(files[1])
ca <- pdb[grepl("^ATOM", pdb) & substr(pdb, 13, 16) == " CA "]
residues <- data.frame(chain = substr(ca, 22, 22),
                       resno = as.integer(substr(ca, 23, 26)),
                       bfactor = as.numeric(substr(ca, 61, 66)))

palettes <- list(
  "blue-white-red" = c("blue", "white", "red"),
  "viridis" = c("#440154", "#3B528B", "#21908C", "#5DC863", "#FDE725"),
  "black-yellow" = c("black", "yellow")
)

# The color R expects for a residue of a colorByValue() map (the same rules
# the viewer uses: specific chain/structure rows win, otherwise na_color).
expected_color <- function(cv, structure, chain, resno) {
  s <- as.integer(cv$structure); ch <- as.character(cv$chain)
  hit <- as.integer(cv$resno) == resno & (is.na(s) | s == structure) &
    (is.na(ch) | ch == chain)
  if (!any(hit)) return(cv$na_color)
  score <- (!is.na(s[hit])) * 2 + (!is.na(ch[hit]))
  as.character(cv$color)[hit][which.max(score)]
}

swatch <- function(hex) {
  if (is.null(hex)) return(tags$code("-"))
  tagList(tags$span(style = sprintf(
    "display:inline-block;width:14px;height:14px;background:%s;border:1px solid #888;vertical-align:middle;margin-right:4px", hex)),
    tags$code(hex))
}

js <- HTML("
// Color that NGL's colormaker gives the CA atom of a residue, read from the
// representation itself (not recomputed), sent back as input$ngl_color.
Shiny.addCustomMessageHandler('readColor', function(m) {
  var tries = 0;
  function attempt() {
    var w = HTMLWidgets.find('#viewer');
    var s = w && w.getStructure();
    var stage = w && w.getStage();
    var comp = s && s[m.structure - 1];
    var repr = comp && comp.reprList.filter(function(r) { return r.name === m.name; })[0];
    if (!repr || stage.tasks.count > 0) {
      if (++tries < 50) return setTimeout(attempt, 200);
      return Shiny.setInputValue('ngl_color', null);
    }
    // The parameters NGL itself passes when it builds the representation
    var cm = NGL.ColormakerRegistry.getScheme(repr.repr.getColorParams());
    var index = -1;
    comp.structure.eachAtom(function(a) {
      if (index < 0 && a.resno === m.resno && a.chainname === m.chain && a.atomname === 'CA') index = a.index;
    });
    if (index < 0) return Shiny.setInputValue('ngl_color', null);
    var c = cm.atomColor(comp.structure.getAtomProxy(index));
    Shiny.setInputValue('ngl_color', { hex: '#' + ('000000' + c.toString(16)).slice(-6).toUpperCase(),
                                       scheme: repr.repr.colorScheme, at: Date.now() });
  }
  setTimeout(attempt, 300);
});
// Number of colorByValue() schemes in NGL's registry, to show they are freed
setInterval(function() {
  if (!window.NGL || !window.Shiny || !Shiny.setInputValue) return;
  var n = Object.keys(NGL.ColormakerRegistry.userSchemes)
    .filter(function(k) { return /\\|colorbyvalue$/.test(k); }).length;
  if (n !== window.__schemeCount) { window.__schemeCount = n; Shiny.setInputValue('scheme_count', n); }
}, 500);
")

ui <- fluidPage(
  tags$head(tags$script(js)),
  titlePanel("F1: colorByValue() - color residues by values from R"),
  wellPanel(
    tags$b("What to try"),
    tags$ol(
      tags$li("Move the ", tags$b("k"), " slider: the cartoon colors change along the chain, the plot below shows the same colors, and the camera does not move (updateColor() through the proxy)."),
      tags$li(tags$b("Click a residue"), " in the viewer: the state panel shows its value, the color R computed and the color NGL actually uses. They should match (", tags$b("match: yes"), "). Move the slider again: both update."),
      tags$li("Change the ", tags$b("palette"), ", untick ", tags$b("domain from the values"), " and set your own range (values outside it get the end colors), and change ", tags$b("na_color"), "."),
      tags$li("Tick ", tags$b("leave residues out"), ": those residues are not in the table and get na_color."),
      tags$li("Choose ", tags$b("Score = B-factor"), ": a real per-residue value read from the PDB file in R."),
      tags$li("Tick ", tags$b("second copy"), ": structure 2 (to the right) gets the reversed score through the ", tags$code("structure"), " column. Click a residue in each copy."),
      tags$li("Press ", tags$b("Add selection"), ": a ball+stick selection of residues 1-10 colored black to yellow with a named vector (", tags$code("c(\"A:1\" = 1, ...)"), ") through addSelection()."),
      tags$li("Below the plot, ", tags$b("Code for these settings"), " shows the R code that gives what you see; it changes with every control."),
      tags$li("Switch ", tags$b("apply with"), " to re-render: each change now rebuilds the viewer (camera resets). In both modes the number of registered schemes stays constant: old ones are freed.")
    )
  ),
  sidebarLayout(
    sidebarPanel(width = 3,
      radioButtons("score", "Score", c("sin(resno / k)" = "sin", "B-factor" = "bfactor")),
      sliderInput("k", "k", 1, 20, 5, step = 0.5),
      selectInput("palette", "palette", names(palettes)),
      checkboxInput("domain_auto", "domain from the values (default)", TRUE),
      conditionalPanel("!input.domain_auto",
        fluidRow(column(6, numericInput("dmin", "min", -0.5)),
                 column(6, numericInput("dmax", "max", 0.5)))),
      selectInput("na_color", "na_color", c("grey", "black", "green", "#FF00FF")),
      checkboxInput("gap", "leave residues 20-30 out of the table", FALSE),
      checkboxInput("two", "second copy, colored by the reversed score (structure column)", FALSE),
      actionButton("add_sel", "Add selection"),
      actionButton("remove_sel", "Remove selection"),
      hr(),
      radioButtons("mode", "apply with",
                   c("updateColor() (proxy)" = "proxy", "re-render" = "rerender"))
    ),
    mainPanel(width = 9,
      tabsetPanel(
        tabPanel("Shiny",
          fluidRow(
            column(8, NGLVieweROutput("viewer", height = "480px")),
            column(4,
              wellPanel(
                tags$b("State"),
                uiOutput("state")
              )
            )
          ),
          plotOutput("plot", height = "260px"),
          tags$h4("Code for these settings"),
          tags$p(tags$small("Updates as you change the controls; paste it into your own app.")),
          verbatimTextOutput("code")
        ),
        tabPanel("Static widget (console)",
          p("colorByValue() also works outside Shiny. Paste this in the R console (from the project root):"),
          tags$pre(paste(
            'pkgload::load_all()',
            'scores <- data.frame(chain = "A", resno = 1:46, value = sin(1:46 / 5))',
            'NGLVieweR("tests/testthat/fixtures/1crn.pdb") %>%',
            '  addRepresentation("cartoon",',
            '    param = list(color = colorByValue(scores, domain = c(-1, 1))))',
            sep = "\n"))
        )
      )
    )
  )
)

server <- function(input, output, session) {

  # The values to color by, as computed in R
  scores <- reactive({
    value <- if (input$score == "sin") sin(residues$resno / input$k) else residues$bfactor
    df <- data.frame(chain = residues$chain, resno = residues$resno, value = value)
    if (input$gap) df <- df[!df$resno %in% 20:30, ]
    df
  })

  color_map <- reactive({
    df <- scores()
    if (input$two) {
      reversed <- df
      reversed$value <- max(df$value) + min(df$value) - df$value
      df <- rbind(cbind(structure = 1L, df), cbind(structure = 2L, reversed))
    }
    domain <- if (input$domain_auto) NULL else c(input$dmin, input$dmax)
    tryCatch(
      colorByValue(df, palette = palettes[[input$palette]], domain = domain,
                   na_color = input$na_color),
      error = function(e) {
        showNotification(conditionMessage(e), type = "error")
        NULL
      })
  })

  output$viewer <- renderNGLVieweR({
    cv <- if (input$mode == "rerender") color_map() else isolate(color_map())
    req(cv)
    w <- NGLVieweR(files[1]) %>%
      addRepresentation("cartoon", param = list(name = "cartoon", color = cv))
    if (input$two) {
      w <- w %>% addStructure(files[2]) %>%
        addRepresentation("cartoon", param = list(name = "cartoon", color = cv))
    }
    w %>% stageParameters(backgroundColor = "white")
  })

  observeEvent(color_map(), {
    req(input$mode == "proxy", color_map())
    NGLVieweR_proxy("viewer") %>% updateColor("cartoon", color_map())
  }, ignoreInit = TRUE)

  # Whether the selection is shown, for the code panel
  selection_shown <- reactiveVal(FALSE)
  observeEvent(input$add_sel, selection_shown(TRUE))
  observeEvent(input$remove_sel, selection_shown(FALSE))
  observeEvent(input$two, selection_shown(FALSE), ignoreInit = TRUE)

  observeEvent(input$add_sel, {
    values <- setNames(1:10, paste0("A:", 1:10))
    NGLVieweR_proxy("viewer") %>%
      removeSelection("selection") %>%
      addSelection("ball+stick", param = list(name = "selection", sele = "1-10",
        color = colorByValue(values, palette = c("black", "yellow"))))
  })
  observeEvent(input$remove_sel, {
    NGLVieweR_proxy("viewer") %>% removeSelection("selection")
  })

  # Clicked residue: structure, chain, resno
  clicked <- reactiveVal(NULL)
  observeEvent(input$viewer_selection, {
    label <- input$viewer_selection
    m <- regmatches(label, regexec("\\]([0-9]+):([A-Za-z0-9]+)", label))[[1]]
    if (length(m) == 3 && !is.null(input$viewer_selectionStructure)) {
      clicked(list(structure = input$viewer_selectionStructure,
                   resno = as.integer(m[2]), chain = m[3]))
    }
  })
  observeEvent(input$two, clicked(NULL), ignoreInit = TRUE)

  # Ask the viewer for the color it uses, whenever the residue or the map changes
  observe({
    cl <- clicked(); color_map()
    req(cl)
    session$sendCustomMessage("readColor", c(cl, name = "cartoon"))
  })

  output$state <- renderUI({
    cv <- color_map()
    cl <- clicked()
    n <- input$scheme_count
    schemes <- tags$p(tags$b("colorByValue schemes in NGL: "), if (is.null(n)) "-" else n,
      tags$br(), tags$small("1 per representation after a render, 1 per updateColor() call; should not grow while you move the slider."))
    if (is.null(cv)) return(schemes)
    if (is.null(cl)) {
      return(tagList(tags$p(tags$i("Click a residue.")),
                     tags$p(tags$b("domain: "), paste(signif(cv$domain, 3), collapse = " to ")),
                     schemes))
    }
    df <- scores()
    value <- df$value[df$resno == cl$resno & df$chain == cl$chain]
    if (input$two && cl$structure == 2 && length(value)) {
      value <- max(df$value) + min(df$value) - value
    }
    expected <- expected_color(cv, cl$structure, cl$chain, cl$resno)
    ngl <- input$ngl_color$hex
    tagList(
      tags$p(tags$b("residue: "), sprintf("%s:%d, structure %d", cl$chain, cl$resno, cl$structure)),
      tags$p(tags$b("value: "), if (length(value)) signif(value, 4) else "not in the table (na_color)"),
      tags$p(tags$b("domain: "), paste(signif(cv$domain, 3), collapse = " to ")),
      tags$p(tags$b("color from R: "), swatch(expected)),
      tags$p(tags$b("color in NGL: "), swatch(ngl)),
      tags$p(tags$b("match: "),
             if (is.null(ngl)) "-" else if (identical(ngl, expected))
               tags$span(style = "color:green", "yes") else tags$span(style = "color:red", "NO")),
      tags$p(tags$b("NGL scheme id: "), tags$code(input$ngl_color$scheme)),
      schemes
    )
  })

  # The same colors in a plot, with a legend drawn from palette and domain
  # The R code for the current settings
  output$code <- renderText({
    quoted <- function(x) {
      x <- if (is.character(x)) paste0('"', x, '"') else vapply(x, format, "")
      if (length(x) == 1) x else paste0("c(", paste(x, collapse = ", "), ")")
    }
    files_code <- if (input$two) {
      'files <- c("1crn.pdb", "1crn_moved2.pdb")  # the same protein, moved'
    } else 'file <- "1crn.pdb"'
    file1 <- if (input$two) "files[1]" else "file"

    data_code <- if (input$score == "sin") {
      sprintf('scores <- data.frame(chain = "A", resno = 1:46, value = sin(1:46 / %s))', input$k)
    } else {
      c("# CA B-factors, read in R",
        sprintf("pdb <- readLines(%s)", file1),
        'ca <- pdb[grepl("^ATOM", pdb) & substr(pdb, 13, 16) == " CA "]',
        "scores <- data.frame(chain = substr(ca, 22, 22),",
        "                     resno = as.integer(substr(ca, 23, 26)),",
        "                     value = as.numeric(substr(ca, 61, 66)))")
    }
    if (input$gap) {
      data_code <- c(data_code, "# Residues left out of the table get na_color",
                     "scores <- scores[!scores$resno %in% 20:30, ]")
    }
    if (input$two) {
      data_code <- c(data_code,
        "# Structure 2 gets the reversed score: the structure column picks the structure",
        "reversed <- transform(scores, value = max(value) + min(value) - value)",
        "scores <- rbind(cbind(structure = 1, scores), cbind(structure = 2, reversed))")
    }

    args <- c("scores", paste("palette =", quoted(palettes[[input$palette]])))
    if (!input$domain_auto) args <- c(args, paste("domain =", quoted(c(input$dmin, input$dmax))))
    if (input$na_color != "grey") args <- c(args, paste("na_color =", quoted(input$na_color)))
    map_code <- paste0("map <- colorByValue(", paste(args, collapse = ",\n                    "), ")")
    defaults <- c(if (input$domain_auto) "domain = range of the values",
                  if (input$na_color == "grey") 'na_color = "grey"')
    if (length(defaults)) {
      map_code <- c(paste("# Defaults used:", paste(defaults, collapse = ", ")), map_code)
    }

    viewer_code <- function(color) {
      c(sprintf("NGLVieweR(%s) %%>%%", file1),
        sprintf('  addRepresentation("cartoon", param = list(name = "cartoon", color = %s))%s',
                color, if (input$two) " %>%" else ""),
        if (input$two) c("  addStructure(files[2]) %>%",
          sprintf('  addRepresentation("cartoon", param = list(name = "cartoon", color = %s))', color)))
    }
    apply_code <- if (input$mode == "proxy") {
      c("# Server: render once, then recolor through the proxy (the camera stays)",
        "output$viewer <- renderNGLVieweR({",
        paste0("  ", viewer_code("\"grey\"")),
        "})",
        "observe({",
        paste0("  ", data_code),
        paste0("  ", strsplit(paste(map_code, collapse = "\n"), "\n")[[1]]),
        '  NGLVieweR_proxy("viewer") %>% updateColor("cartoon", map)',
        "})")
    } else {
      c("# Server: every change re-renders the viewer (the camera resets)",
        "output$viewer <- renderNGLVieweR({",
        paste0("  ", data_code),
        paste0("  ", strsplit(paste(map_code, collapse = "\n"), "\n")[[1]]),
        paste0("  ", viewer_code("map")),
        "})")
    }

    selection_code <- if (selection_shown()) {
      c("", "# The selection: a named vector \"chain:resno\" = value",
        "observeEvent(input$add_sel, {",
        '  values <- setNames(1:10, paste0("A:", 1:10))',
        '  NGLVieweR_proxy("viewer") %>%',
        '    addSelection("ball+stick", param = list(name = "selection", sele = "1-10",',
        '      color = colorByValue(values, palette = c("black", "yellow"))))',
        "})")
    }

    paste(c(files_code, "", apply_code, selection_code), collapse = "\n")
  })

  output$plot <- renderPlot({
    cv <- color_map()
    req(cv)
    s <- as.integer(cv$structure)
    first <- is.na(s) | s == 1
    df <- scores()
    layout(matrix(1:2, 1), widths = c(5, 1))
    par(mar = c(4, 4, 1, 1))
    plot(NA, xlim = c(1, 46), ylim = range(c(df$value, cv$domain)), xlab = "resno",
         ylab = "value", main = "")
    rect(df$resno - 0.45, min(c(df$value, cv$domain)), df$resno + 0.45, df$value,
         col = as.character(cv$color)[first], border = NA)
    missing <- setdiff(residues$resno, df$resno)
    if (length(missing)) {
      rect(missing - 0.45, par("usr")[3], missing + 0.45, par("usr")[4],
           col = cv$na_color, border = NA)
    }
    # Legend
    par(mar = c(4, 1, 1, 4))
    steps <- seq(cv$domain[1], cv$domain[2], length.out = 50)
    ramp <- grDevices::colorRampPalette(as.character(cv$palette))(50)
    image(1, steps, matrix(steps, 1), col = ramp, axes = FALSE, xlab = "", ylab = "")
    axis(4, las = 1)
    box()
  })
}

shinyApp(ui, server)
