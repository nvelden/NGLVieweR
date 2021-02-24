//<------------------------- /addRepresentation/ ------------------------->

//Convert color selection to string
function colorMaker(color){
 return NGL.ColormakerRegistry.addSelectionScheme(color);
}

//Apply function over array by key
//Only apply over objects
function arrHandler(arr, key){
  for(var i = 0; i < arr.length; ++i){
    if(typeof arr[i][key] === 'object' && arr[i][key] !== null){
    arr[i][key] = colorMaker(arr[i][key]);
  }
 }
 return arr;
}

//<------------------------- /Update functions/ ------------------------->

//Make chart available to R after rendering
function getNGLStage(id){

  // Get the HTMLWidgets object
  var htmlWidgetsObj = HTMLWidgets.find("#" + id);

  // Get chart object after initial rendering
  if(htmlWidgetsObj !== undefined){
    var NGLObj = htmlWidgetsObj.getStage();
     return(NGLObj);
  } else {
    return(undefined);
  }
}

//Make structure available to R after rendering
function getNGLStructure(id){

  // Get the HTMLWidgets object
  var htmlWidgetsObj = HTMLWidgets.find("#" + id);

  // Get structure object after initial rendering
  if(htmlWidgetsObj !== undefined){
    var NGLObj = htmlWidgetsObj.getStructure();
     return(NGLObj);
  } else {
    return(undefined);
  }
}

