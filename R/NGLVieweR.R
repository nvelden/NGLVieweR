#'Create a NGLVieweR
#'@description NGLVieweR can be used to visualize and interact with Protein Data
#'Bank (PDB) and structural files in R and Shiny applications. It includes a set
#'of API functions to manipulate the viewer after creation in Shiny.
#'@details The package is based on the
#'\href{http://nglviewer.org/ngl/api/}{NGL.js} JavaScript library. To see the
#'full set of features please read the official manual of NGL.js.
#'@param data A PDB entry code (e.g. \code{"7CID"}), the path to a structure
#'  file, or the file contents as a single string or a vector of lines (e.g.
#'  from \code{readLines()}). Files compressed with gzip, bzip2 or xz
#'  (\code{.gz}, \code{.bz2}, \code{.xz}) are decompressed.
#'@param format Input format (cif, mmcif, mcif, pdb, ent, pqr, gro, sdf, sd,
#'  mol2), with or without a leading dot. Needed for file contents and for
#'  files without a recognisable extension. Binary formats such as MMTF are
#'  not supported. For a PDB entry code, \code{"pdb"} or \code{"cif"} picks
#'  the file downloaded from RCSB; without \code{format} the PDB-format file
#'  is used, and the mmCIF file if there is none (large entries such as
#'  ribosomes only exist as mmCIF). For such entries, \code{format = "cif"}
#'  saves the failed request for the PDB-format file.
#'@param width,height Must be a valid CSS unit (like \code{'100\%'},
#'  \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'  string and have \code{'px'} appended.
#'@param elementId optional element Id
#'@return A \code{NGLVieweR} \code{htmlwidgets} object.
#'@seealso
#'* [NGLVieweR_proxy()] for handling of API calls after rendering.
#'* [NGLVieweR_example()] See example "API" and "basic".
#'@examples
#'
#' # Example 1: Most Basic
#'NGLVieweR("7CID") %>%
#'  addRepresentation("cartoon", 
#'  param = list(name = "cartoon", colorScheme="residueindex"))
#'
#' # Example 2: Advanced
#' NGLVieweR("7CID") %>%
#'   stageParameters(backgroundColor = "white") %>%
#'   setQuality("high") %>%
#'   setSpin(FALSE) %>%
#'   addRepresentation("cartoon",
#'     param = list(
#'       name = "cartoon",
#'       colorScheme = "residueindex"
#'     )
#'   ) %>%
#'   addRepresentation("ball+stick",
#'     param = list(
#'       name = "ball+stick",
#'       colorValue = "red",
#'       colorScheme = "element",
#'       sele = "200"
#'     )
#'   ) %>%
#'   addRepresentation("label",
#'     param = list(
#'       name = "label", sele = "200:A.O",
#'       showBackground = TRUE,
#'       backgroundColor = "black",
#'       backgroundMargin = 2,
#'       backgroundOpacity = 0.5,
#'       showBorder = TRUE,
#'       colorValue = "white"
#'     )
#'   ) %>%
#'   addRepresentation("surface",
#'     param = list(
#'       name = "surface",
#'       colorValue = "white",
#'       opacity = 0.1
#'     )
#'   ) %>%
#'   zoomMove("200", "200", 2000, -20)
#'
#' #---------------------Using Shiny-------------------------
#'
#' # App 1: Basic Example
#' if (interactive()) {
#'   library(shiny)
#'   ui <- fluidPage(NGLVieweROutput("structure"))
#'   server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         addRepresentation("cartoon",
#'           param = list(
#'             name = "cartoon",
#'             colorScheme = "residueindex"
#'           )
#'         ) %>%
#'         addRepresentation("ball+stick",
#'           param = list(
#'             name = "ball+stick",
#'             sele = "1-20",
#'             colorScheme = "element"
#'           )
#'         ) %>%
#'         stageParameters(backgroundColor = "black") %>%
#'         setQuality("high") %>%
#'         setFocus(0) %>%
#'         setSpin(TRUE)
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'
#'# App 2: Example with API calls
#'if (interactive()) {
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
#'       ) %>%
#'       stageParameters(backgroundColor = "black") %>%
#'       setQuality("high") %>%
#'       setFocus(0) %>%
#'       setSpin(TRUE)
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
#'
#'@importFrom htmlwidgets createWidget
#'
#'@export
NGLVieweR <- function(data, format = NULL, width = NULL, height = NULL, elementId = NULL) {

  # Validate data input
  if (missing(data)) {
    stop("NGLVieweR: Please specify a PDB entry code or file",
      call. = FALSE
    )
  }
  
  input <- .parse_structure_input(data, format, "NGLVieweR")

  # forward options using x
  x <- list()
  # Add structure data and parameters
  x$structures <- list()
  
  new_structure <- list(
    file_ext = input$file_ext,
    data = input$data,
    type = input$type,
    fallback = input$fallback,
    addRepresentation = list(
      type = list(),
      values = list()
    ),
    setScale = 1,
    setRotation = list(),
    setPosition = list(),
    zoomMove = list()
  )
  
  x$structures <- c(x$structures, list(new_structure))
  x$superpose = list()
 
  # Add stage parameters. Quality and focus are only sent when setQuality()
  # or setFocus() is used, so they cannot override stageParameters().
  x$setRock <- FALSE
  x$setSpin <- FALSE

  x$stageParameters <- list()
  
  
  
  # create widget
  htmlwidgets::createWidget(
    name = "NGLVieweR",
    x,
    width = width,
    height = height,
    package = "NGLVieweR",
    elementId = elementId
  )
}

#'Set stage parameters
#'
#'@description Set stage parameters.
#'@param NGLVieweR A NGLVieweR object.
#'@param ... Options controlling the stage. Most common options are
#'  \code{backgroundColor}, \code{rotateSpeed}, \code{zoomSpeed},
#'  \code{hoverTimeout} and \code{lightIntensity}. For a full list of options,
#'  see the "stageParameters" method in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@details Options that are not given use the NGL.js defaults. In Shiny, this
#'  also holds when \code{renderNGLVieweR()} re-renders: an option set in an
#'  earlier render but not in the current one returns to its default.
#'
#'  [setFocus()] and [setQuality()] are shortcuts that set clipping, fog and
#'  quality. Options named here win over them: for example
#'  \code{setFocus(50) \%>\% stageParameters(fogFar = 60)} keeps the clipping
#'  of focus 50 with \code{fogFar} 60.
#'
#'  All NGL.js stage parameters can be set here or changed later with
#'  [updateStage()]. For example:
#'
#'  * **Clipping**: \code{clipNear}, \code{clipFar}, \code{clipDist},
#'    \code{clipMode} ("scene" or "camera") and \code{clipScale} ("relative"
#'    or "absolute").
#'  * **Fog**: \code{fogNear} and \code{fogFar}.
#'  * **Lighting**: \code{lightColor}, \code{lightIntensity},
#'    \code{ambientColor} and \code{ambientIntensity}.
#'  * **Camera**: \code{cameraType} ("perspective", "orthographic" or
#'    "stereo"), \code{cameraFov} and \code{cameraEyeSep}.
#'  * **Mouse controls**: \code{mousePreset} ("default", "pymol", "coot" or
#'    "astexviewer").
#'@return Returns list of stage parameters to \code{NGLVieweR}
#'  \code{htmlwidgets} object.
#'@seealso
#'* [updateStage()]
#'* [NGLVieweR_example()] See example "basic".
#'@examples
#'NGLVieweR("7CID") %>%
#'  stageParameters(backgroundColor = "white", zoomSpeed = 1) %>%
#'  addRepresentation("cartoon", param = list(name = "cartoon", colorScheme="residueindex"))
#'
#' # Orthographic camera, PyMOL mouse controls and fog
#' NGLVieweR("7CID") %>%
#'   stageParameters(
#'     cameraType = "orthographic",
#'     mousePreset = "pymol",
#'     fogNear = 40,
#'     fogFar = 80
#'   ) %>%
#'   addRepresentation("cartoon")
#'
#' if (interactive()) {
#'   library(shiny)
#'   ui <- fluidPage(NGLVieweROutput("structure"))
#'   server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         stageParameters(backgroundColor = "white", zoomSpeed = 1) %>%
#'         addRepresentation("cartoon",
#'           param = list(name = "cartoon", colorScheme = "residueindex")
#'         )
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'
#'@export
stageParameters <- function(NGLVieweR, ...) {

  NGLVieweR$x$stageParameters <- list(...)
  NGLVieweR

}

#'Set selection parameters
#'
#'@description Set selection parameters.
#'@param NGLVieweR A NGLVieweR object.
#'@param proximity Set distance in angstrom for atoms to return in proximity of
#'  selection. Default = \code{3}.
#'@param level Set level on which atoms in proximity of selection are returned.
#'  Options are "residue" (default) or atom".
#'@return Returns list of selection parameters to \code{NGLVieweR}
#'  \code{htmlwidgets} object.
#'@examples
#'NGLVieweR("7CID") %>%
#'  addRepresentation("cartoon") %>%
#'  selectionParameters(3, "residue")
#'
#' # Shiny context
#' if (interactive()) {
#'    library(shiny)
#'    ui <- fluidPage(NGLVieweROutput("structure"))
#'    server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         addRepresentation("cartoon") %>%
#'         selectionParameters(3, "residue")
#'     })
#'     observeEvent(input$structure_selAround, {
#'       NGLVieweR_proxy("structure") %>% removeSelection("selAround")
#'       NGLVieweR_proxy("structure") %>%
#'         addSelection(
#'           "ball+stick",
#'           param =
#'             list(
#'               name = "selAround",
#'               sele = input$structure_selAround,
#'               colorValue = "grey"
#'             )
#'         )
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'
#'@export
selectionParameters <- function(NGLVieweR, proximity = 3, level = "residue") {
  opts <- list(proximity = proximity, level = level)
  NGLVieweR$x$selectionParameters <- opts
  NGLVieweR
}

#'Add structure
#'
#'@description Add a structure to the NGLVieweR object, either from a PDB entry
#'  code, a file, or directly from the R environment.
#'
#'@param NGLVieweR A NGLVieweR object.
#'@param data Structure data to be added, in the same forms as in
#'  [NGLVieweR()]: a PDB entry code (e.g. "7CID"), a file path (also
#'  compressed with gzip, bzip2 or xz), or the file contents as a single
#'  string or a vector of lines.
#'@param format Format of the structure, as in [NGLVieweR()] (e.g. "pdb",
#'  "cif"). Needed for file contents and when the format cannot be inferred
#'  from the file name. For a PDB entry code it picks the file downloaded
#'  from RCSB, as in [NGLVieweR()].
#'
#'@details This function allows you to add a structure to the NGLVieweR widget.
#'  You can add the structure using a PDB entry code, by specifying a local
#'  file, or by providing the structure data directly. If the format is not
#'  clear from the input, you may need to specify it using the `format`
#'  parameter.
#'
#'@return An updated NGLVieweR object with the added structure.
#'
#'
#' @examples
#' NGLVieweR("1CRN") %>%
#'   addRepresentation("cartoon", param = list(color = "blue")) %>%
#'   addStructure("1CRN") %>%
#'   addRepresentation("cartoon", param = list(color = "orange")) %>%
#'   setPosition(x = 20, y = 0, z = 0) %>%
#'   setRotation(x = 2, y = 0, z = 0, degrees = FALSE) %>% 
#'   setScale(0.5)
#'
#' # Note: The first "1CRN" structure is represented in blue, while the second 
#' # "1CRN" structure is represented in orange. Transformations such as 
#' # setPosition, setRotation, and setScale apply to the second 
#' # (most recently added) structure.
#'
#'@export
addStructure <- function(NGLVieweR, data, format = NULL) {

  # Validate data input
  if (missing(data)) {
    stop("addStructure: Please specify a PDB entry code or file",
         call. = FALSE
    )
  }
  input <- .parse_structure_input(data, format, "addStructure")

  # Add structure to the NGLVieweR object
  new_structure <- list(
    file_ext = input$file_ext,
    data = input$data,
    type = input$type,
    fallback = input$fallback,
    addRepresentation = list(
      type = list(),
      values = list()
    ),
    setScale = 1,
    setRotation = list(),
    setPosition = list(),
    zoomMove = list()
  )
  
  NGLVieweR$x$structures <- append(NGLVieweR$x$structures, list(new_structure))
  
  NGLVieweR
  
}

#' Set superpose
#'
#' @description Enable or disable superposition of multiple structures, with
#' options to specify the reference structure and selection strings for
#' alignment.
#' @param NGLVieweR A NGLVieweR object.
#' @param reference The index of the reference structure to align other
#'   structures to. Defaults to 1 (the first loaded structure). The reference
#'   keeps its coordinates; every other structure is moved onto it.
#' @param sele_reference Selection string for the reference structure,
#'   specifying which parts to align. Mandatory.
#' @param sele_target Selection string for each target structure, specifying
#'   which parts to align. Mandatory.
#' @param superpose Logical; if \code{TRUE} (default), enable superposition of
#'   multiple structures. Set to \code{FALSE} to disable.
#' @return Sets the `superpose` list in the \code{NGLVieweR} \code{htmlwidgets}
#'   object.
#' @examples
#' NGLVieweR("1GZM") %>%
#'   addRepresentation("cartoon", param = list(color = "blue")) %>%
#'   addStructure("1U19") %>%
#'   addRepresentation("cartoon", param = list(color = "orange")) %>%
#'   setSuperpose(
#'     reference = 1, 
#'     sele_reference = ":A", 
#'     sele_target = ":A", 
#'     superpose = TRUE
#'   )
#' @export
setSuperpose <- function(NGLVieweR, reference = 1, sele_reference, sele_target, superpose = TRUE) {
  
  if (!is.numeric(reference) || length(reference) != 1 || !is.finite(reference) ||
      reference < 1 || reference != round(reference)) {
    stop("setSuperpose: 'reference' must be a single whole number of 1 or more.",
         call. = FALSE)
  }

  # Ensure sele_reference and sele_target are provided
  if (missing(sele_reference) || missing(sele_target)) {
    stop("Both 'sele_reference' and 'sele_target' parameters are mandatory and must be specified.")
  }
  
  # Set superpose list in the NGLVieweR object
  NGLVieweR$x$superpose <- list(
    superpose = superpose,
    reference = reference,
    seleReference = sele_reference,
    seleTarget = sele_target
  )
  
  NGLVieweR
}

#'Add representation
#'
#'@description Add a representation and its parameters.
#'
#'@param NGLVieweR A NGLVieweR object.
#'@param type Type of representation. Most common options are "cartoon",
#'  "ball+stick", "line", "surface", "ribbon" and "label". For a full list of
#'  options, see the "structureRepresentation" method in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@param param Options for the different types of representations. Most common
#'  options are \code{name}, \code{opacity}, \code{colorScheme}, \code{sele},
#'  \code{colorValue} and \code{visibility}. For a full list of options, see the
#'  general "RepresentationParameters" method and type specific Label-,
#'  Structure- and Surface- RepresentationParameters in the official
#'  \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.
#'@details \code{type} and \code{param} are passed to NGL.js as they are, so
#'  every NGL.js representation and parameter works, including ones not
#'  listed above. Some useful ones:
#'
#'  * **Other styles**: "spacefill", "licorice", "hyperball", "backbone",
#'    "trace", "tube", "rope", "rocket", "point", "axes", "helixorient",
#'    "unitcell" and "contact".
#'  * **Measurements**: "distance" (\code{atomPair}), "angle"
#'    (\code{atomTriple}) and "dihedral" (\code{atomQuad}). Give each as a list
#'    of selections, e.g. \code{atomPair = list(list("1.CA", "20.CA"))}. These
#'    are only drawn; the measured values are not returned to R or Shiny.
#'  * **Biological assemblies and crystal packing**: the \code{assembly}
#'    parameter shows a biological unit such as "BU1", the unit cell
#'    ("UNITCELL") or a 3x3x3 block of unit cells ("SUPERCELL"). The default
#'    is the asymmetric unit ("AU"). Only assemblies defined in the file can
#'    be shown.
#'@return List of representation parameters to \code{NGLVieweR}
#'  \code{htmlwidgets} object.
#'@seealso
#'* [addSelection()]
#'* [NGLVieweR_example()] See example "basic".
#'@examples
#' NGLVieweR("7CID") %>%
#'   stageParameters(backgroundColor = "black") %>%
#'   addRepresentation("cartoon", 
#'   param = list(name = "cartoon", colorValue = "blue")) %>%
#'   addRepresentation("ball+stick",
#'     param = list(
#'       name = "ball+stick", sele = "241",
#'       colorScheme = "element", colorValue = "yellow"
#'     ) 
#'   ) %>%
#'   addRepresentation("label",
#'     param = list(
#'       name = "label",
#'       showBackground = TRUE,
#'       labelType = "res",
#'       color = "black",
#'       backgroundColor = "white",
#'       backgroundOpacity = 0.8,
#'       sele = ":A and 241 and .CG"
#'     )
#'   )
#'
#' # Biological assembly
#' NGLVieweR("1RUZ") %>%
#'   addRepresentation("cartoon", param = list(assembly = "BU1"))
#'
#' # Distance measurement
#' NGLVieweR("1CRN") %>%
#'   addRepresentation("cartoon") %>%
#'   addRepresentation("distance",
#'     param = list(atomPair = list(list("1.CA", "20.CA")))
#'   )
#'
#' # Shiny context
#' if (interactive()) {
#'   library(shiny)
#'   ui <- fluidPage(NGLVieweROutput("structure"))
#'   server <- function(input, output) {
#'     output$structure <- renderNGLVieweR({
#'       NGLVieweR("7CID") %>%
#'         stageParameters(backgroundColor = "black") %>%
#'         addRepresentation("cartoon",
#'           param = list(name = "cartoon", colorValue = "blue")
#'         ) %>%
#'         addRepresentation("ball+stick",
#'           param = list(
#'             name = "ball+stick", sele = "241",
#'             colorScheme = "element"
#'           )
#'         ) %>%
#'         addRepresentation("label",
#'           param = list(
#'             name = "label",
#'             showBackground = TRUE,
#'             labelType = "res",
#'             colorValue = "black",
#'             backgroundColor = "white",
#'             backgroundOpacity = 0.8,
#'             sele = ":A and 241 and .CG"
#'           )
#'         )
#'     })
#'   }
#'   shinyApp(ui, server)
#' }
#'@export
addRepresentation <- function(NGLVieweR, type, param = list()) {

  last_structure_index <- length(NGLVieweR$x$structures)
  
  NGLVieweR$x$structures[[last_structure_index]]$addRepresentation$type <- append(
    NGLVieweR$x$structures[[last_structure_index]]$addRepresentation$type, 
    type
  )
  NGLVieweR$x$structures[[last_structure_index]]$addRepresentation$values <- append(
    NGLVieweR$x$structures[[last_structure_index]]$addRepresentation$values, 
    list(param)
  )
  
  NGLVieweR
}

#'Set rock
#'
#'@description Set rock animation
#'@param NGLVieweR A NGLVieweR object.
#'@param rock If \code{TRUE} (default), start rocking and stop spinning.
#'@details Only one animation can run at a time. If both \code{setRock(TRUE)}
#'  and \code{setSpin(TRUE)} are used, the structure spins.
#'@return setRock parameter to \code{TRUE} or \code{FALSE} in \code{NGLVieweR}
#'  \code{htmlwidgets} object.
#'@family animations
#'@seealso
#'* [setSpin()]
#'* [updateRock()]
#'@examples
#'NGLVieweR("7CID") %>%
#'  addRepresentation("cartoon", param=list(name="cartoon", colorValue="blue")) %>%
#'  setRock(TRUE)
#'@export
setRock <- function(NGLVieweR, rock = TRUE) {
  
  NGLVieweR$x$setRock <- rock
  NGLVieweR
}

#'Set Spin
#'
#'@description Set Spin animation
#'@param NGLVieweR A NGLVieweR object.
#'@param spin If \code{TRUE} (default), start spinning and stop rocking
#'@details Only one animation can run at a time. If both \code{setSpin(TRUE)}
#'  and \code{setRock(TRUE)} are used, the structure spins.
#'@return setSpin parameter to \code{TRUE} or \code{FALSE} in \code{NGLVieweR}
#'  \code{htmlwidgets} object.
#'@family animations
#'@seealso
#'* [setRock()]
#'* [updateSpin()]
#'@examples
#'NGLVieweR("7CID") %>%
#'  addRepresentation("cartoon", param=list(name="cartoon", colorValue="blue")) %>%
#'  setSpin(TRUE)
#'@export
setSpin <- function(NGLVieweR, spin = TRUE) {

  NGLVieweR$x$setSpin <- spin
  NGLVieweR
}

#' Set Scale
#'
#' @description
#' Set the scale factor for the representation
#' @param NGLVieweR A NGLVieweR object.
#' @param scale A numeric value indicating the scale factor (default is 1).
#' @return Updated \code{NGLVieweR} object with new scale parameter.
#' @family transformations
#' @seealso
#' * [zoomMove()]
#' * [setRotation()]
#' * [setPosition()]
#' @examples
#' NGLVieweR("7CID") %>%
#' addRepresentation("cartoon", 
#' param=list(name="cartoon", colorValue="blue")) %>%
#' setScale(2)
#' @export
setScale <- function(NGLVieweR, scale = 1) {
  
  last_structure_index <- length(NGLVieweR$x$structures)
  NGLVieweR$x$structures[[last_structure_index]]$setScale <- scale
  
  NGLVieweR
}

#' Set zoomMove
#'
#' @description Add a zoom animation
#' @param NGLVieweR A NGLVieweR object.
#' @param center Target distance of selected atoms/residues. See the section
#'   "selection-language" in the official \href{https://nglviewer.org/}{NGL.js}
#'   manual.
#' @param zoom Target zoom of selected atoms/residues. See the section
#'   "selection-language" in the official \href{https://nglviewer.org/}{NGL.js}
#'   manual.
#' @param duration Optional animation time in milliseconds (default = 0).
#' @param z_offSet Optional zoom offset value (default = 0).
#' @details Applies to the last structure added. The camera moves after all
#'   structures are loaded and superposed (see [setSuperpose()]). If
#'   \code{zoomMove()} is used for several structures, the last one is used
#'   (with a warning). The center is that of the atom coordinates, so it does
#'   not follow [setPosition()], [setRotation()] or [setScale()].
#' @return List of zoomMove parameters to \code{NGLVieweR} \code{htmlwidgets}
#'   object.
#' @family transformations
#' @seealso
#' * [setScale()]
#' * [setRotation()]
#' * [setPosition()]
#' @examples
#' NGLVieweR("7CID") %>%
#' stageParameters(backgroundColor = "white") %>%
#'   addRepresentation("cartoon", param=list(name="cartoon", colorValue="red")) %>%
#'   addRepresentation("ball+stick", param=list(name="ball+stick",
#'                                              colorValue="yellow",
#'                                              colorScheme="element",
#'                                              sele="200")) %>%
#'   zoomMove("200:A.C", "200:A.C", 2000, -20)
#' @export
zoomMove <- function(NGLVieweR, center, zoom, duration = 0, z_offSet = 0){
  opts <- list(center = center, zoom = zoom, duration = duration, z_offSet = z_offSet)
  
  last_structure_index <- length(NGLVieweR$x$structures)
  earlier <- vapply(NGLVieweR$x$structures[-last_structure_index],
                    function(s) length(s$zoomMove) > 0, logical(1))
  if (any(earlier)) {
    warning("zoomMove: an earlier structure also has a zoomMove(); only the last one is used.",
            call. = FALSE)
  }
  NGLVieweR$x$structures[[last_structure_index]]$zoomMove <- opts
  
  NGLVieweR
}

#' Rotate View
#'
#' @description Set rotation for the representation
#' @param NGLVieweR A NGLVieweR object.
#' @param x Rotation angle around the x-axis. Default is 0.
#' @param y Rotation angle around the y-axis. Default is 0.
#' @param z Rotation angle around the z-axis. Default is 0.
#' @param degrees A logical value. If TRUE (default), the input angles are
#'   assumed to be in degrees and will be converted to radians. If FALSE, the
#'   angles are assumed to be in radians.
#' @return NGLVieweR object with updated rotateView parameters.
#' @family transformations
#' @seealso
#' * [setScale()]
#' * [zoomMove()]
#' * [setPosition()]
#' @examples
#' NGLVieweR("7CID") %>%
#' stageParameters(backgroundColor = "white") %>%
#' addRepresentation("cartoon", param=list(name="cartoon", colorValue="red")) %>%
#' addRepresentation("ball+stick", param=list(name="ball+stick",
#' colorValue="yellow",
#' colorScheme="element",
#' sele="200")) %>%
#' setRotation(30, 45, 60, degrees = TRUE)
#' @export
setRotation <- function(NGLVieweR, x=0, y=0, z=0, degrees=TRUE){
  
  if(degrees) {
    # Convert degrees to radians
    x <- x * (pi / 180)
    y <- y * (pi / 180)
    z <- z * (pi / 180)
  }
  
  opts <- list(x = x, y = y, z = z)
  
  last_structure_index <- length(NGLVieweR$x$structures)
  NGLVieweR$x$structures[[last_structure_index]]$setRotation <- opts
  
  NGLVieweR
}

#' Set Position
#'
#' @description
#' Set position for the representation
#' @param NGLVieweR A NGLVieweR object.
#' @param x Position along the x-axis in angstroms. Default is 0.
#' @param y Position along the y-axis in angstroms. Default is 0.
#' @param z Position along the z-axis in angstroms. Default is 0.
#' @return NGLVieweR object with updated setPosition parameters.
#' @family transformations
#' @seealso
#' * [setScale()]
#' * [zoomMove()]
#' * [setRotation()]
#' @examples
#' NGLVieweR("7CID") %>%
#' stageParameters(backgroundColor = "white") %>%
#' addRepresentation("cartoon", param=list(name="cartoon", colorValue="red")) %>%
#' addRepresentation("ball+stick", param=list(name="ball+stick",
#' colorValue="yellow",
#' colorScheme="element",
#' sele="200")) %>%
#' setPosition(25, 0, 0)
#' @export
setPosition <- function(NGLVieweR, x=0, y=0, z=0){
  
  opts <- list(x = x, y = y, z = z)
  
  last_structure_index <- length(NGLVieweR$x$structures)
  NGLVieweR$x$structures[[last_structure_index]]$setPosition <- opts
  
  NGLVieweR
}

#'Set Quality
#'
#'@description Set Quality
#'@param NGLVieweR A NGLVieweR object.
#'@param quality Set rendering quality. Can be "low", "medium" (default) or
#'  "high".
#'@details Without \code{setQuality()} the viewer uses the NGL.js default
#'  ("medium"). A \code{quality} given in [stageParameters()] wins over
#'  \code{setQuality()}.
#'@return setQuality parameter in \code{NGLVieweR} \code{htmlwidgets} object.
#'@family options
#'@examples
#'NGLVieweR("7CID") %>%
#'   addRepresentation("cartoon",
#'   param=list(name="cartoon", colorValue="blue")) %>%
#'   setQuality("medium")
#'@export
setQuality <- function(NGLVieweR, quality = "medium") {

  NGLVieweR$x$setQuality <- quality
  NGLVieweR
}

#'Set Focus
#'
#'@description
#'Set Focus
#'@param NGLVieweR A NGLVieweR object.
#'@param focus Set focus between 0 (default) to 100.
#'@details The focus sets the clipping planes and the fog (the NGL.js stage
#'  parameters \code{clipNear}, \code{clipFar}, \code{fogNear} and
#'  \code{fogFar}). Without \code{setFocus()} the viewer uses the NGL.js
#'  defaults (with the default \code{clipScale = "relative"} these equal focus
#'  0). Values of these four parameters given in [stageParameters()] win over
#'  \code{setFocus()}.
#'@return setFocus parameter in \code{NGLVieweR} \code{htmlwidgets} object.
#'@seealso [updateFocus()]
#'@family options
#'@examples
#'NGLVieweR("7CID") %>%
#'   addRepresentation("cartoon", 
#'   param=list(name="cartoon", colorValue="blue")) %>%
#'   setFocus(0)
#' @export
setFocus <- function(NGLVieweR, focus = 0) {

  NGLVieweR$x$setFocus <- focus
  NGLVieweR
}