#'Add a selection
#'
#'@description Add a new selection to a NGLVieweR object in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param type Type of representation. Most common options are "cartoon",
#'  "ball+stick", "surface", "ribbon" and "label".
#'@param param Options for the different types of representations. Most common
#'  options are \code{name}, \code{opacity}, \code{colorScheme}, \code{sele},
#'  \code{colorValue} and \code{visibility}. For a full list of options, see the
#'  general "RepresentationParameters" method and type specific Label-,
#'  Structure- and Surface- RepresentationParameters in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@param structureIndex (optional) The index of the specific structure to which
#'  the selection should be added (index 0 for the first). If not specified, the
#'  selection will be applied to all loaded structures.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family selections
#'@seealso
#'* [updateRepresentation()] Update an existing NGLVieweR representation.
#'* [NGLVieweR_example()] See example "addSelection".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("7CID") %>%
#'  addSelection("ball+stick", param = list(name="sel1",
#'                                          sele="1-20",
#'                                          colorValue="yellow",
#'                                          colorScheme="element"
#'                                          ))
#' }
#'
#' if (interactive()) {
#' library(shiny)
#'
#' ui <- fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       textInput("selection", "Selection", "1-20"),
#'       selectInput("type", "Type", c("ball+stick", "cartoon", "backbone")),
#'       selectInput("color", "Color", c("orange", "grey", "white")),
#'       actionButton("add", "Add"),
#'       actionButton("remove", "Remove")
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server <- function(input, output) {
#'   output$structure <- renderNGLVieweR({
#'     NGLVieweR("7CID") %>%
#'       addRepresentation("cartoon",
#'         param = list(name = "cartoon", colorScheme = "residueindex")
#'       )
#'   })
#'   observeEvent(input$add, {
#'     NGLVieweR_proxy("structure") %>%
#'       addSelection(isolate(input$type),
#'         param =
#'           list(
#'             name = "sel1",
#'             sele = isolate(input$selection),
#'             colorValue = isolate(input$color)
#'           )
#'       )
#'   })
#'
#'   observeEvent(input$remove, {
#'     NGLVieweR_proxy("structure") %>%
#'       removeSelection("sel1")
#'   })
#' }
#' shinyApp(ui, server)
#' }
#'@export
addSelection <- function(NGLVieweR_proxy, type, param = list(), structureIndex = NULL) {
  
  if (!is.null(structureIndex)) {
    param$structureIndex <- structureIndex
  }
  
  message <- list(id = NGLVieweR_proxy$id, type = type, param = param)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:addSelection", message)
  
  return(NGLVieweR_proxy)
}

#'Remove a selection
#'
#'@description Remove an existing NGLVieweR selection in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param name Name of selection to be removed.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family selections
#'@seealso
#'* [NGLVieweR_example()] See example "removeSelection".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("structure") %>%
#'      removeSelection("sel1")
#' }
#'
#' if (interactive()) {
#'   library(shiny)
#'
#'   ui <- fluidPage(
#'     titlePanel("Viewer with API inputs"),
#'     sidebarLayout(
#'       sidebarPanel(
#'         textInput("selection", "Selection", "1-20"),
#'         selectInput("type", "Type", c("ball+stick", "cartoon", "backbone")),
#'         selectInput("color", "Color", c("orange", "grey", "white")),
#'         actionButton("add", "Add"),
#'         actionButton("remove", "Remove")
#'       ),
#'       mainPanel(
#'         NGLVieweROutput("structure")
#'       )
#'     )
#'   )
#'   server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         addRepresentation("cartoon",
#'           param = list(name = "cartoon", colorScheme = "residueindex")
#'         )
#'     })
#'     observeEvent(input$add, {
#'       NGLVieweR_proxy("structure") %>%
#'         addSelection(isolate(input$type),
#'           param =
#'             list(
#'               name = "sel1",
#'               sele = isolate(input$selection),
#'               colorValue = isolate(input$color)
#'             )
#'         )
#'     })
#'
#'     observeEvent(input$remove, {
#'       NGLVieweR_proxy("structure") %>%
#'         removeSelection("sel1")
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'@export
removeSelection <- function(NGLVieweR_proxy, name) {

  message <- list(id = NGLVieweR_proxy$id, name = name)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:removeSelection", message)

  return(NGLVieweR_proxy)
}

#'Update a selection
#'
#'@description Update the selected residues of an existing NGLVieweR selection
#'in
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param name Name of selection.
#'@param sele Selected atoms/residues. See the section "selection-language" in
#'  the official \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family selections
#'@seealso
#'* [NGLVieweR_example()] See example "updateSelection".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("structure") %>%
#'   updateSelection("ball+stick", sele = "1-20")
#' }
#'
#' if (interactive()) {
#'   library(shiny)
#'   ui <- fluidPage(
#'     titlePanel("Viewer with API inputs"),
#'     sidebarLayout(
#'       sidebarPanel(
#'         textInput("selection", "Selection", "1-20"),
#'         actionButton("update", "Update")
#'       ),
#'       mainPanel(
#'         NGLVieweROutput("structure")
#'       )
#'     )
#'   )
#'   server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         addRepresentation("cartoon",
#'           param = list(name = "cartoon", color = "red")
#'         ) %>%
#'         addRepresentation("ball+stick",
#'           param = list(
#'             name = "ball+stick",
#'             colorValue = "yellow",
#'             colorScheme = "element",
#'             sele = "1-20"
#'           )
#'         )
#'     })
#'     observeEvent(input$update, {
#'       NGLVieweR_proxy("structure") %>%
#'         updateSelection("ball+stick", sele = isolate(input$selection))
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'@export
updateSelection <- function(NGLVieweR_proxy, name = name, sele = "none"){

  message <- list(id = NGLVieweR_proxy$id, name = name, sele = sele)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateSelection", message)

  return(NGLVieweR_proxy)

}

#'Update color of a selection
#'
#'@description Update color of an existing NGLVieweR selection in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param name Name of selection to alter the color.
#'@param color Can be a colorValue (color name or HEX code) or colorScheme (e.g.
#'  "element", "resname", "random" or "residueindex"). For a full list of
#'  options, see the "Colormaker" section in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family updates
#'@seealso
#'* [NGLVieweR_example()] See example "updateColor".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("structure") %>%
#'      updateColor("cartoon", "red")
#' }
#'
#' if (interactive()) {
#'   library(shiny)
#'   library(colourpicker)
#'
#'   ui <- fluidPage(
#'     titlePanel("Viewer with API inputs"),
#'     sidebarLayout(
#'       sidebarPanel(
#'         colourInput("color", "red", "red"),
#'         actionButton("update", "Update"),
#'       ),
#'       mainPanel(
#'         NGLVieweROutput("structure")
#'       )
#'     )
#'   )
#'   server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         addRepresentation("cartoon",
#'           param = list(name = "cartoon", color = "residueindex")
#'         )
#'     })
#'     observeEvent(input$update, {
#'       NGLVieweR_proxy("structure") %>%
#'         updateColor("cartoon", isolate(input$color))
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'@export
updateColor <- function(NGLVieweR_proxy, name, color) {

  message <- list(id = NGLVieweR_proxy$id, name = name, color = color)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateColor", message)

  return(NGLVieweR_proxy)
}

#'Snapshot
#'
#'@description Make a snapshot of a NGLVieweR object in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param fileName Optional name for Snapshot (default = "Snapshot").
#'@param param Of type list, can be; antialias \code{TRUE/FALSE}, trim
#'  \code{TRUE/FALSE}, transparent \code{TRUE/FALSE} or scale \code{numeric}.
#'  For a full list of options, see "makeImage" and "ImageParameters" in the
#'  official \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family options
#'@seealso [NGLVieweR_example()] See example "snapshot".
#'@examples
#'\dontrun{
#'NGLVieweR_proxy("structure") %>%
#'snapShot("Snapshot", param = list(
#'                                antialias = TRUE,
#'                                trim = TRUE,
#'                                transparent = TRUE,
#'                                scale = 1))
#'}
#'
#' if (interactive()) {
#'   library(shiny)
#'
#'   ui <- fluidPage(
#'     titlePanel("Viewer with API inputs"),
#'     sidebarLayout(
#'       sidebarPanel(
#'         actionButton("snapshot", "Snapshot"),
#'       ),
#'       mainPanel(
#'         NGLVieweROutput("structure")
#'       )
#'     )
#'   )
#'   server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         addRepresentation("cartoon",
#'           param = list(
#'             name = "cartoon",
#'             color = "residueindex"
#'           )
#'         )
#'     })
#'     observeEvent(input$snapshot, {
#'       NGLVieweR_proxy("structure") %>%
#'         snapShot("Snapshot",
#'           param = list(
#'             antialias = TRUE,
#'             trim = TRUE,
#'             transparent = TRUE,
#'             scale = 1
#'           )
#'         )
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'@export
snapShot <- function(NGLVieweR_proxy, fileName = "Snapshot", param = list()) {

  message <- list(id = NGLVieweR_proxy$id, fileName = fileName, param = param)

  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:snapShot", message)

  return(NGLVieweR_proxy)
}

#'Update visibility
#'
#'@description Hide or show an existing NGLVieweR selection in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param name Name of selection to alter the color.
#'@param value Hide \code{FALSE} or show \code{TRUE} selection. For a full
#'  description see "setVisibility" in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family updates
#'@seealso [NGLVieweR_example()] See example "updateVisibility".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("structure") %>%
#'  updateVisibility("cartoon", value = TRUE)
#' }
#'
#' if (interactive()) {
#' library(shiny)
#'
#' ui = fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       actionButton("show", "Show"),
#'       actionButton("hide", "Hide"),
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server = function(input, output) {
#'   output$structure <- renderNGLVieweR({
#'     NGLVieweR("7CID") %>%
#'       addRepresentation("cartoon",
#'                         param = list(name = "cartoon", color="residueindex"))
#'   })
#'   observeEvent(input$show, {
#'     NGLVieweR_proxy("structure") %>%
#'       updateVisibility("cartoon", value = TRUE)
#'
#'   })
#'   observeEvent(input$hide, {
#'     NGLVieweR_proxy("structure") %>%
#'       updateVisibility("cartoon", value = FALSE)
#'
#'   })
#' }
#' shinyApp(ui, server)
#' }
#'@export
updateVisibility <- function(NGLVieweR_proxy, name, value = FALSE) {

  message <- list(id = NGLVieweR_proxy$id, name = name, value = value)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateVisibility", message)

  return(NGLVieweR_proxy)
}

#'Update Representation
#'
#'@description Update an existing NGLVieweR representation in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param name Name of representation to alter the color.
#'@param param Options for the different types of representations. Most common
#'  options are \code{name}, \code{opacity}, \code{colorScheme},
#'  \code{colorValue} and \code{visibility}. For a full list of options, see the
#'  general "RepresentationParameters" method and type specific Label-,
#'  Structure- and Surface- RepresentationParameters in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family updates
#'@seealso
#'* [addSelection()] Add a new selection to a NGLVieweR object.
#'* [addRepresentation()]
#'* [NGLVieweR_example()] See example "updateRepresentation".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("structure") %>%
#'   updateRepresentation("cartoon",
#'     param = list(
#'       name = "cartoon",
#'       color = isolate(input$color),
#'       opacity = isolate(input$opacity)
#'     )
#'   )
#' }
#'
#' if (interactive()) {
#' library(shiny)
#'
#' ui = fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       selectInput("color", "Color", c("red", "white", "blue")),
#'       sliderInput("opacity", "Opacity", 0, 1, 1),
#'       actionButton("update", "Update"),
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server = function(input, output) {
#'   output$structure <- renderNGLVieweR({
#'     NGLVieweR("7CID") %>%
#'       addRepresentation("cartoon",
#'                         param = list(name = "cartoon", color="red"))
#'   })
#' observeEvent(input$update, {
#'   NGLVieweR_proxy("structure") %>%
#'     updateRepresentation("cartoon",
#'       param = list(
#'         color = isolate(input$color),
#'         opacity = isolate(input$opacity)
#'       )
#'     )
#' })
#'  }
#' shinyApp(ui, server)
#' }
#'@export
updateRepresentation <- function(NGLVieweR_proxy, name, param = list()) {

  message <- list(id = NGLVieweR_proxy$id, name = name, param = param)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateRepresentation", message)

  return(NGLVieweR_proxy)
}

#'Update Stage
#'
#'@description Update an existing NGLVieweR stage in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param param Of type list. Most common options are \code{backgroundColor},
#'  \code{rotateSpeed}, \code{zoomSpeed}, \code{hoverTimeout} and
#'  \code{lightIntensity}. For a full list of options, see the "StageParameters"
#'  method in the official \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family updates
#'@seealso
#'* [stageParameters()]
#'* [NGLVieweR_example()] See example "updateStage".
#'@examples
#'\dontrun{
#' NGLVieweR("7CID") %>%
#'  addRepresentation("cartoon",
#'                    param = list(name = "cartoon", color="red")) %>%
#'  stageParameters(backgroundColor = "black")
#' }
#'
#' if (interactive()) {
#' library(shiny)
#'
#' ui = fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       selectInput("background", "Background", c("black", "white", "blue")),
#'       actionButton("update", "Update"),
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server <- function(input, output) {
#'   output$structure <- renderNGLVieweR({
#'     NGLVieweR("7CID") %>%
#'       addRepresentation("cartoon",
#'         param = list(name = "cartoon", color = "red")
#'       ) %>%
#'       stageParameters(backgroundColor = "black")
#'   })
#'   observeEvent(input$update, {
#'     NGLVieweR_proxy("structure") %>%
#'       updateStage(
#'       param = list("backgroundColor" = isolate(input$background)))
#'   })
#' }
#' shinyApp(ui, server)
#' }
#' @export
updateStage <- function(NGLVieweR_proxy, param = list()) {

  message <- list(id = NGLVieweR_proxy$id, param = param)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateStage", message)

  return(NGLVieweR_proxy)
}

#'Update Focus
#'
#'@description Update the focus of an existing NGLVieweR object in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param focus Numeric value between 0-100 (default = 0).
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family options
#'@seealso
#'* [setFocus()]
#'* [NGLVieweR_example()] See example "updateFocus".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("structure") %>%
#'   updateFocus(focus = 50)
#'}
#'
#' if (interactive()) {
#'   library(shiny)
#'   ui = fluidPage(
#'     titlePanel("Viewer with API inputs"),
#'     sidebarLayout(
#'       sidebarPanel(
#'         sliderInput("focus", "Focus", 0, 100, 50)
#'       ),
#'       mainPanel(
#'         NGLVieweROutput("structure")
#'       )
#'     )
#'   )
#'   server = function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         addRepresentation("cartoon",
#'         param = list(name = "cartoon", color= "red"))
#'     })
#'     observeEvent(input$focus, {
#'       NGLVieweR_proxy("structure") %>%
#'         updateFocus(input$focus)
#'     })
#'   }
#' shinyApp(ui, server)
#'}
#'@export
updateFocus <- function(NGLVieweR_proxy, focus = 0){

  message <- list(id = NGLVieweR_proxy$id, focus = focus)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateFocus", message)

  return(NGLVieweR_proxy)

}

#'Update Rock
#'
#'@description Start rock animation and stop spinning. Works on an existing
#'NGLVieweR object in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param rock  If \code{TRUE} (default), start rocking and stop spinning.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family animations
#'@seealso
#'* [setRock()]
#'* [NGLVieweR_example()] See example "updateAnimation".
#'@examples
#'\dontrun{
#'NGLVieweR_proxy("structure") %>% updateRock(TRUE)
#'}
#'
#'if (interactive()) {
#'library(shiny)
#'
#' ui = fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       radioButtons("animate", label = "Animation",
#'       choices = c("None", "Spin", "Rock"), selected = "None")
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server = function(input, output) {
#'   output$structure <- renderNGLVieweR({
#'     NGLVieweR("7CID") %>%
#'       addRepresentation("cartoon",
#'       param = list(name = "cartoon", color="red"))
#'   })
#'
#'   observeEvent(input$animate,{
#'     if(input$animate == "Rock"){
#'       NGLVieweR_proxy("structure") %>%
#'       updateRock(TRUE)
#'     } else if(input$animate == "Spin") {
#'       NGLVieweR_proxy("structure") %>%
#'       updateSpin(TRUE)
#'     } else{
#'       NGLVieweR_proxy("structure") %>%
#'       updateRock(FALSE) %>%
#'       updateSpin(FALSE)
#'     }
#'   })
#'  }
#' shinyApp(ui, server)
#'}
#'@export
updateRock <- function(NGLVieweR_proxy, rock = TRUE){

  message <- list(id = NGLVieweR_proxy$id, rock = rock)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateRock", message)

  return(NGLVieweR_proxy)
}

#'Update Spin
#'
#'@description Start spin animation and stop rocking. Works on an existing
#'NGLVieweR object in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param spin  If \code{TRUE} (default), start spinning and stop rocking.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family animations
#'@seealso
#'* [setSpin()]
#'* [NGLVieweR_example()] See example "updateAnimation".
#'@examples
#'\dontrun{
#'NGLVieweR_proxy("structure") %>% updateRock(TRUE)
#'}
#'if (interactive()) {
#'library(shiny)
#'
#' ui = fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       radioButtons("animate", label = "Animation",
#'                    choices = c("None", "Spin", "Rock"), selected = "None")
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server = function(input, output) {
#'   output$structure <- renderNGLVieweR({
#'     NGLVieweR("7CID") %>%
#'       addRepresentation("cartoon",
#'       param = list(name = "cartoon", color="red"))
#'   })
#'
#'   observeEvent(input$animate,{
#'     if(input$animate == "Rock"){
#'       NGLVieweR_proxy("structure") %>%
#'        updateRock(TRUE)
#'     } else if(input$animate == "Spin") {
#'       NGLVieweR_proxy("structure") %>%
#'        updateSpin(TRUE)
#'     } else{
#'       NGLVieweR_proxy("structure") %>%
#'        updateRock(FALSE) %>%
#'        updateSpin(FALSE)
#'     }
#'   })
#'  }
#' shinyApp(ui, server)
#'}
#'@export
updateSpin <- function(NGLVieweR_proxy, spin = TRUE){

  message <- list(id = NGLVieweR_proxy$id, spin = spin)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateSpin", message)

  return(NGLVieweR_proxy)
}

#'Fullscreen
#'
#'@description Put viewer in fullscreen. Works in Shinymode.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param fullscreen If \code{TRUE} put viewer in fullscreen.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family options
#'@seealso [NGLVieweR_example()] See example "updateFullscreen".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("structure") %>% updateFullscreen()
#' }
#'
#' if (interactive()) {
#' library(shiny)
#'
#' ui <- fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       actionButton("fullscreen", "Fullscreen"),
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server = function(input, output) {
#'  output$structure <- renderNGLVieweR({
#'   NGLVieweR("7CID") %>%
#'     addRepresentation("cartoon",
#'       param = list(name = "cartoon", color = "red")
#'     )
#' })
#'
#'   observeEvent(input$fullscreen, {
#'   NGLVieweR_proxy("structure") %>%
#'     updateFullscreen()
#' })
#' }
#'   shinyApp(ui, server)
#' }
#'@export
updateFullscreen <- function(NGLVieweR_proxy, fullscreen = TRUE){

  message <- list(id = NGLVieweR_proxy$id, fullscreen = fullscreen)
  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateFullscreen", 
                                            message)

  return(NGLVieweR_proxy)
}

#'Update zoomMove
#'
#'@description Add a zoom animation on an existing NGLVieweR object.
#'@param NGLVieweR_proxy A NGLVieweR object.
#'@param center Target distance of selected atoms/residues. See the section
#'  "selection-language" in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@param zoom Target zoom of selected atoms/residues. See the section
#'  "selection-language" in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@param duration Optional animation time in milliseconds (default = 0).
#'@param z_offSet Optional zoom offset value (default = 0).
#'@param structureIndex Optional index of the structure to target for the zoom
#'  animation. If `NULL` (default), the first structure (index 0) is targeted.
#'@return API call containing \code{NGLVieweR} \code{id} and list of message
#'  parameters.
#'@family animations
#'@seealso
#'* [zoomMove()]
#'* [NGLVieweR_example()] See example "updatezoomMove".
#'@examples
#'\dontrun{
#' NGLVieweR_proxy("structure") %>% updateZoomMove(center = "200",
#'                                                zoom = "200",
#'                                                z_offSet = 80,
#'                                                duration = 2000)
#' }
#'
#' if (interactive()) {
#' library(shiny)
#'
#' ui = fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       textInput("center", "Center", "200"),
#'       textInput("zoom", "Zoom", "200"),
#'       numericInput("zoomOffset", "Zoom offset", 80,0,100),
#'       numericInput("duration", "Duration", 2000,0,2000),
#'       actionButton("zoom", "Zoom"),
#'       actionButton("reset", "Reset")
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server = function(input, output) {
#'   output$structure <- renderNGLVieweR({
#'     NGLVieweR("7CID") %>%
#'       addRepresentation("cartoon",
#'       param = list(name = "cartoon", color="red")) %>%
#'       addRepresentation("ball+stick",
#'       param = list(name = "ball+stick", sele="200"))
#'   })
#'
#' observeEvent(input$zoom, {
#'   NGLVieweR_proxy("structure") %>%
#'     updateZoomMove(
#'       center = isolate(input$center),
#'       zoom = isolate(input$zoom),
#'       z_offSet = isolate(input$zoomOffset),
#'       duration = isolate(input$duration)
#'     )
#' })
#'
#' observeEvent(input$reset, {
#'   NGLVieweR_proxy("structure") %>%
#'     updateZoomMove(
#'       center = "*",
#'       zoom = "*",
#'       z_offSet = 0,
#'       duration = 1000
#'     )
#' })
#' }
#' shinyApp(ui, server)
#' }
#'@export
updateZoomMove <- function(NGLVieweR_proxy, center, zoom, duration = 0, z_offSet = 0, structureIndex = NULL) {
  
  message <- list(
    id = NGLVieweR_proxy$id,
    center = center,
    zoom = zoom,
    duration = duration,
    z_offSet = z_offSet
  )
  
  if (!is.null(structureIndex)) {
    message$structureIndex <- structureIndex
  }
  

  NGLVieweR_proxy$session$sendCustomMessage("NGLVieweR:updateZoomMove", message)
  
  return(NGLVieweR_proxy)
}

#' @importFrom magrittr %>%
#' @export
magrittr::`%>%`

