library(shiny)
library(NGLVieweR)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      radioButtons("animate", label = "Animation", choices = c("None", "Spin", "Rock"), selected = "None")
    ),
    mainPanel(
      NGLVieweROutput("structure")
    )
  )
)
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon", param = list(name = "cartoon", color="red"))
  })

  observeEvent(input$animate,{
    if(input$animate == "Rock"){
      NGLVieweR_proxy("structure") %>% updateRock(TRUE)
    } else if(input$animate == "Spin") {
      NGLVieweR_proxy("structure") %>% updateSpin(TRUE)
    } else{
      NGLVieweR_proxy("structure") %>% updateRock(FALSE) %>% updateSpin(FALSE)
    }
  })
}
shinyApp(ui, server)


