library(shiny)
library(NGLVieweR)

 ui = fluidPage(
   titlePanel("Viewer with API inputs"),
   sidebarLayout(
     sidebarPanel(
       textInput("selection", "Selection", "1-20"),
       selectInput("type", "Type", c("ball+stick", "cartoon", "backbone")),
       selectInput("color", "Color", c("orange", "grey", "white")),
       actionButton("add", "Add"),
       actionButton("remove", "Remove")
     ),
     mainPanel(
       NGLVieweROutput("structure")
     )
   )
 )
 server = function(input, output) {
   output$structure <- renderNGLVieweR({
     NGLVieweR("7CID") %>%
       addRepresentation("cartoon", param = list(name = "cartoon", colorScheme="residueindex"))
   })
   observeEvent(input$add, {
     NGLVieweR_proxy("structure") %>%
       addSelection(isolate(input$type),
                    param =
                    list(name="sel1",
                    sele=isolate(input$selection),
                    colorValue=isolate(input$color)))
   })

   observeEvent(input$remove, {
     NGLVieweR_proxy("structure") %>%
       removeSelection("sel1")
   })
 }
shinyApp(ui, server)
