pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
library(shiny)

# Repro for bug #11: the sequence inputs change shape with the number of
# structures. Launch from the project root:
#   shiny::runApp("dev/repro/11-input-shapes", launch.browser = TRUE)

fixtures <- normalizePath("../../../tests/testthat/fixtures")

ui <- fluidPage(
  titlePanel("Bug #11: sequence inputs change shape"),
  wellPanel(
    tags$b("What to look for"),
    tags$p("Switch between 1 and 2 structures and compare str() of the inputs. ",
           "FIX: the new input$viewer_residues has the same shape for 1 or 2 structures; ",
           "the old inputs below are unchanged on purpose. ",
           "With 1 structure, _sequence has one letter per residue and _resno is numeric. ",
           "With 2 structures, _sequence has one long string per structure and _resno ",
           "becomes text like \"1,2,3,...\". Code written for one structure (e.g. length(seq), ",
           "seq[5], resno + 1) silently gives wrong results after addStructure().")
  ),
  fluidRow(
    column(4,
      radioButtons("n", "Number of structures", c(1, 2), inline = TRUE),
      h4("Typical code written for one structure"),
      tags$p("Old inputs (unchanged): breaks with 2 structures."),
      verbatimTextOutput("typical"),
      h4("The same with input$viewer_residues"),
      tags$p("Works for 1 and 2 structures (here: structure 1)."),
      verbatimTextOutput("typical_new")
    ),
    column(8, h4("str() of the inputs"), verbatimTextOutput("str"))
  ),
  NGLVieweROutput("viewer", height = "300px")
)

server <- function(input, output, session) {
  output$viewer <- renderNGLVieweR({
    w <- NGLVieweR(file.path(fixtures, "1crn.pdb")) %>% addRepresentation("cartoon")
    if (input$n == 2) {
      w <- w %>% addStructure(file.path(fixtures, "1crn_moved2.pdb")) %>%
        addRepresentation("cartoon")
    }
    w
  })
  output$str <- renderText({
    req(input$viewer_sequence)
    paste(capture.output({
      cat("input$viewer_sequence:\n");  str(input$viewer_sequence, vec.len = 3, nchar.max = 40)
      cat("\ninput$viewer_resno:\n");     str(input$viewer_resno, vec.len = 3, nchar.max = 40)
      cat("\ninput$viewer_chainname:\n"); str(input$viewer_chainname, vec.len = 3, nchar.max = 40)
      cat("\ninput$viewer_PDB:\n");       str(input$viewer_PDB, vec.len = 1, nchar.max = 40)
      cat("\ninput$viewer_residues (new, same shape for 1 or 2 structures):\n")
      str(input$viewer_residues, vec.len = 3)
    }), collapse = "\n")
  })
  output$typical_new <- renderText({
    res <- input$viewer_residues
    req(res)
    s1 <- res[res$structure == 1 & res$letter != "X", ]
    paste0(
      "nrow(s1):        ", nrow(s1), "   (number of residues)\n",
      "s1$letter[5]:    ", s1$letter[5], "\n",
      "s1$resno[1] + 1: ", s1$resno[1] + 1, "\n",
      "structures:      ", paste(unique(res$structure), collapse = ", ")
    )
  })
  output$typical <- renderText({
    seq <- input$viewer_sequence
    req(seq)
    paste0(
      "length(seq):  ", length(seq), "   (number of residues?)\n",
      "seq[5]:       ", substr(paste(seq[5]), 1, 20), "\n",
      "resno[1] + 1: ", tryCatch(format(input$viewer_resno[[1]] + 1),
                                 error = function(e) paste("ERROR:", conditionMessage(e)))
    )
  })
}

shinyApp(ui, server)
