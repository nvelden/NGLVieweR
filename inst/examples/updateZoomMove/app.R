library(shiny)
library(NGLVieweR)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      textInput("center", "Center", "200"),
      textInput("zoom", "Zoom", "200"),
      numericInput("zoomOffset", "Zoom offset", 80,0,100),
      numericInput("duration", "Duration", 2000,0,2000),
      actionButton("zoom", "Zoom"),
      actionButton("reset", "Reset")
    ),
    mainPanel(
      NGLVieweROutput("structure")
    )
  )
)
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon", param = list(name = "cartoon", color="red")) %>%
      addRepresentation("ball+stick", param = list(name = "ball+stick", sele="200"))
  })

  observeEvent(input$zoom,{

    NGLVieweR_proxy("structure") %>% updateZoomMove(center = isolate(input$center),
                                                    zoom = isolate(input$zoom),
                                                    z_offSet = isolate(input$zoomOffset),
                                                    duration = isolate(input$duration))

  })

  observeEvent(input$reset,{

    NGLVieweR_proxy("structure") %>% updateZoomMove(center = "*",
                                                    zoom = "*",
                                                    z_offSet = 0,
                                                    duration = 1000)

  })
}
shinyApp(ui, server)


