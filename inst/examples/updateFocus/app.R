library(shiny)
library(NGLVieweR)

  ui = fluidPage(
    titlePanel("Viewer with API inputs"),
    sidebarLayout(
      sidebarPanel(
        sliderInput("focus", "Focus", 0, 100, 50)
      ),
      mainPanel(
        NGLVieweROutput("structure")
      )
    )
  )
  server = function(input, output) {
    output$structure <- renderNGLVieweR({
      NGLVieweR("7CID") %>%
        addRepresentation("cartoon", param = list(name = "cartoon", color= "red"))
    })
    observeEvent(input$focus, {
      NGLVieweR_proxy("structure") %>%
        updateFocus(input$focus)
    })
  }
shinyApp(ui, server)



