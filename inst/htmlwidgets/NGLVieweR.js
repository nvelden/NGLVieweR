HTMLWidgets.widget({

  name: 'NGLVieweR',

  type: 'output',

  factory: function(el, width, height) {

      var stage = new NGL.Stage(el);
      var structures = null;
      // Options of the latest render, read by the event handlers below
      var currentOpts = null;
      // NGL's default stage parameters and the keys the previous render set
      // with stageParameters(). Keys that the current render no longer sets
      // go back to their default; all other stage parameters are left alone.
      var defaultStageParameters = Object.assign({}, stage.getParameters());
      var renderedStageKeys = [];

      // Event handlers are registered once per widget, not in renderValue,
      // which runs again every time renderNGLVieweR() re-runs. Resizing is
      // handled by the resize() method below.

     //<---------------------------// Shiny inputs // ---------------------------------->
     if (HTMLWidgets.shinyMode) {
      // Send rendering status to shiny
      stage.tasks.signals.countChanged.add(function(count) {
        if (count > 0) {
          Shiny.onInputChange(`${el.id}_rendering`, true);
        } else {
          try {
            Shiny.onInputChange(`${el.id}_rendering`, false);
          } catch (e) {
            // already removed
          }
        }
      });

      // Click handler for the stage
      stage.signals.clicked.add(function(pickingProxy) {
        if (pickingProxy) {
          // Get AA selection details
          Shiny.onInputChange(`${el.id}_selection`, pickingProxy.getLabel());

          // Get list of surrounding atoms
          if (pickingProxy.atom) {
            let atom = pickingProxy.atom;
            let atomName = atom.qualifiedName().split("]").pop();
            let resiName = atomName.split('.')[0];
            let proximity = 3;
            let proxlevel = "residue";

            if (currentOpts && typeof(currentOpts.selectionParameters) !== 'undefined') {
              proximity = currentOpts.selectionParameters["proximity"];
              proxlevel = currentOpts.selectionParameters["level"];
            }

            let selection = proxlevel === "residue" ? new NGL.Selection(resiName) : new NGL.Selection(atomName);
            let selectedComponent = pickingProxy.component;
            let selectedStructure = selectedComponent.structure;

            let atomSet = selectedStructure.getAtomSetWithinSelection(selection, proximity);
            let atomSet2 = selectedStructure.getAtomSetWithinGroup( atomSet );
            Shiny.onInputChange(`${el.id}_selAround`, atomSet2.toSeleString());
          }
        }
      });
     }

    //<---------------------------------// // ------------------------------------------>

    return {
      renderValue: function(opts) {

      currentOpts = opts;

      //In case of Rerendering remove all components
      stage.removeAllComponents();

      //Load timer for rendering
      //console.time("load-to-render");

      //Set stage parameters
      var stageParams = {};
      renderedStageKeys.forEach(function(key) {
        stageParams[key] = defaultStageParameters[key];
      });
      Object.assign(stageParams, opts.stageParameters);
      renderedStageKeys = Object.keys(opts.stageParameters || {});
      stage.setParameters(stageParams);
      stage.setQuality(opts.setQuality);
      stage.setFocus(opts.setFocus);
      
      // Iterate through all structures in the list
        Promise.all(opts.structures.map(function(structureOpts) {
          if (structureOpts.type == "code") {
            return stage.loadFile(structureOpts.data);
          } else if (structureOpts.type == "file") {
            return stage.loadFile(new Blob([structureOpts.data], { type: 'text/plain' }), {
             ext: structureOpts.file_ext
            });
          }
        })).then(function(loaded) {
          
          // Make globaly available
          structures = loaded;
          
          // Initialize arrays to collect data and send to Shiny
          var sequences = [];
          var resnos = [];
          var chainnames = [];
          var PDBdatas = [];

          structures.forEach(function(o, index) {
            var structureOpts = opts.structures[index];

            // Load representation inputs
            var representation = structureOpts.addRepresentation;
            var arrType = representation.type;
            var arrValues = representation.values;
            arrHandler(arrValues, "color");

            // Apply to all representation values objects
            arrValues.forEach((value, repIndex) => {
              let type = arrType[repIndex];
              o.addRepresentation(type, value);
            });
            
            o.autoView();
            stage.autoView();

            // Set Scale
            if (structureOpts.setScale) {
              o.setScale(structureOpts.setScale);
            }

            // Set Rotation
            if (structureOpts.setRotation && Object.keys(structureOpts.setRotation).length > 0) {
              o.setRotation([structureOpts.setRotation.x, structureOpts.setRotation.y, structureOpts.setRotation.z]);
            }

            // Set Position
            if (structureOpts.setPosition && Object.keys(structureOpts.setPosition).length > 0) {
              o.setPosition([structureOpts.setPosition.x, structureOpts.setPosition.y, structureOpts.setPosition.z]);
            }
 
            // Set zoomMove
            var zoomMoveOpts = structureOpts.zoomMove;
            if (zoomMoveOpts && typeof zoomMoveOpts.zoom !== 'undefined') {
              var center = o.getCenter(zoomMoveOpts.center);
              var zoom = o.getZoom(zoomMoveOpts.zoom) + zoomMoveOpts.z_offSet;
              stage.animationControls.zoomMove(center, zoom, zoomMoveOpts.duration);
            }

            // If in Shiny mode, collect AA sequences and other data
            if (HTMLWidgets.shinyMode) {
              var sequence = [];
              var resno = [];
              var chainname = [];
              o.structure.eachResidue(rp => {
                var code = rp.getResname1(); // The single-letter code
                if (code !== 'X') {          // use `rp.resname` for 3-letter
                  sequence.push(code);
                  resno.push(rp.resno);
                  chainname.push(rp.chainname);
                }
              });

              // Write PDB
              var writer = new NGL.PdbWriter(o.structure);
              var PDBdata = writer.getData();
              
              // Collect data for all structures
              sequences.push(sequence);
              resnos.push(resno);
              chainnames.push(chainname);
              PDBdatas.push(PDBdata);
              
            }

          });
          
                      
          if (structures.length > 1 && opts.superpose.superpose) {
              var refIndex = opts.superpose.reference - 1;
              var seleRef = opts.superpose.seleReference;
              var seleTarget = opts.superpose.seleTarget;

              if (!Number.isInteger(refIndex) || refIndex < 0 || refIndex >= structures.length) {
                console.error("NGLVieweR: setSuperpose() reference " + opts.superpose.reference +
                  " is out of range: there are " + structures.length + " structures.");
              } else {
                var sRef = structures[refIndex].structure;

                // Move every other structure onto the reference. NGL.superpose(a, b)
                // moves a onto b, and its selections are in the same order.
                for (var i = 0; i < structures.length; i++) {
                  if (i !== refIndex) {
                    NGL.superpose(structures[i].structure, sRef, true, seleTarget, seleRef);
                    // Update representations to reflect the new position
                    structures[i].updateRepresentations({ position: true });
                  }
                }
              }
          }
          
          if (structures.length > 1) {
            stage.autoView();
          }
          
          // Send data do shiny
          if (HTMLWidgets.shinyMode) {

              Shiny.onInputChange(`${el.id}_PDB`, PDBdatas);
              
              if (sequences.length > 1) {
              sequences = sequences.map(seq => seq.join(''));
              resnos = resnos.map(res => res.join(','));
              chainnames = chainnames.map(chain => chain.join(''));
              }
              
              Shiny.onInputChange(`${el.id}_sequence`, sequences);
              Shiny.onInputChange(`${el.id}_resno`, resnos);
              Shiny.onInputChange(`${el.id}_chainname`, chainnames);
            }
          
      });

     //setRock and setSpin: always apply both, so a re-render with FALSE stops
     //an animation started by an earlier render. NGL runs only one of them;
     //spin is applied last, so spin wins when both are TRUE.
     stage.setRock(opts.setRock === true);
     stage.setSpin(opts.setSpin === true);

   },

      // Called by htmlwidgets (and Shiny) whenever the container changes
      // size: window resizes, tabs being shown, sidebars collapsing
      resize: function(width, height) {
        stage.handleResize();
      },

      //Make stage and structure globally available
      getStage: function(){
        return stage;
      },

      getStructure: function(){
        return structures;
      }

    };
  }
});

//<---------------------------// Shiny handlers // ---------------------------------->

if (HTMLWidgets.shinyMode) {

Shiny.addCustomMessageHandler('NGLVieweR:updateRock', function(message){

  var stage = getNGLStage(message.id);

  if(typeof(stage) !== "undefined"){
    stage.setRock(message.rock);
  }

});

Shiny.addCustomMessageHandler('NGLVieweR:snapShot', function(message){
  Shiny.onInputChange(`${message.id}_rendering`, true);
  setTimeout(function() {

  var stage = getNGLStage(message.id);

  if(typeof(stage) !== "undefined"){
  stage.makeImage(message.param).then(function (blob) {
      NGL.download(blob, message.fileName);

    });
  }

Shiny.onInputChange(`${message.id}_rendering`, false);

  }, 10);
});

Shiny.addCustomMessageHandler('NGLVieweR:updateSpin', function(message){

  var stage = getNGLStage(message.id);
  if(typeof(stage) !== "undefined"){
    stage.setSpin(message.spin);
  }

});

Shiny.addCustomMessageHandler('NGLVieweR:updateFullscreen', function(message){

  var stage = getNGLStage(message.id);
  if(typeof(stage) !== "undefined"){
    stage.toggleFullscreen(document.body);
  }

});

Shiny.addCustomMessageHandler('NGLVieweR:updateZoomMove', function(message) {
  
  // Get the array of loaded structures
  var structures = getNGLStructure(message.id);
  var stage = getNGLStage(message.id);

  // Check if structures are loaded and stage is defined
  if (structures && structures.length > 0 && stage) {
    var structureIndex = message.structureIndex;

    // Check if a specific structure index is provided
    if (typeof structureIndex === 'number' && structureIndex >= 0 && structureIndex < structures.length) {
      // Handle zoomMove for the specified structure
      var structure = structures[structureIndex];
      var center = structure.getCenter(message.center);
      var zoom = structure.getZoom(message.zoom) + (message.z_offSet || 0);

      stage.animationControls.zoomMove(center, zoom, message.duration);
    } else {
      // No specific index provided; default to the first structure
      var structure = structures[0];
      var center = structure.getCenter(message.center);
      var zoom = structure.getZoom(message.zoom) + (message.z_offSet || 0);

      stage.animationControls.zoomMove(center, zoom, message.duration);
    }
  } else {
    console.log("Structures not loaded, unavailable, or stage undefined.");
  }
});

Shiny.addCustomMessageHandler('NGLVieweR:updateFocus', function(message){

  var stage = getNGLStage(message.id);
  if(typeof(stage) !== "undefined"){
    stage.setFocus(message.focus);
  }

});

Shiny.addCustomMessageHandler('NGLVieweR:updateSelection', function(message){

  var stage = getNGLStage(message.id);

  if(typeof(stage) !== "undefined"){

    stage.getRepresentationsByName(message.name).setSelection(message.sele);
  }

});

Shiny.addCustomMessageHandler('NGLVieweR:removeSelection', function(message){

 var stage = getNGLStage(message.id);

 if(typeof(stage) !== "undefined"){
  stage.getRepresentationsByName(message.name).dispose();
 }

});

Shiny.addCustomMessageHandler('NGLVieweR:addSelection', function(message) {

  // Get the array of loaded structures
  var structures = getNGLStructure(message.id);

  // Check if structures are loaded
  if (structures && structures.length > 0) {

    // Prepare the representation parameters
    var param = message.param;
    var color = param['color'];
    var structureIndex = param['structureIndex'];
      
    // Convert color if necessary
    if (typeof color === 'object' && color !== null) {
      param['color'] = colorMaker(param['color']);
    }
    
    // Check if a specific structure index is provided
    if (typeof structureIndex === 'number' && structureIndex >= 0 && structureIndex < structures.length) {
      // Add representation to the specified structure
      structures[structureIndex].addRepresentation(message.type, param);
    } else {
      // No specific index provided; add to all structures
      structures.forEach(function(o) {
        o.addRepresentation(message.type, param);
      });
    }

  } else {
    console.log("Structures not loaded or unavailable.");
  }
});

Shiny.addCustomMessageHandler('NGLVieweR:updateColor', function(message){

  var stage = getNGLStage(message.id);
  var color = message.color;

Shiny.onInputChange(`${message.id}_rendering`, true);
setTimeout(function() {


  if(typeof color === 'object' && color !== null){
    color = colorMaker(color);
  }
  if(typeof(stage) !== "undefined"){
  stage.getRepresentationsByName(message.name).setColor(color);
  }

Shiny.onInputChange(`${message.id}_rendering`, false);

}, 10);

});

Shiny.addCustomMessageHandler('NGLVieweR:updateVisibility', function(message){

  var stage = getNGLStage(message.id);

Shiny.onInputChange(`${message.id}_rendering`, true);
setTimeout(function() {

  if(typeof(stage) !== "undefined"){
  stage.getRepresentationsByName(message.name).setVisibility(message.value);
  }

Shiny.onInputChange(`${message.id}_rendering`, false);

}, 10);
});

Shiny.addCustomMessageHandler('NGLVieweR:updateRepresentation', function(message){

    var stage = getNGLStage(message.id);
    
    var param = message.param;
    var color = param['color'];
      
      //Convert color values
      if(typeof color === 'object' && color !== null){
      param['color'] = colorMaker(param['color']);
      }

Shiny.onInputChange(`${message.id}_rendering`, true);
setTimeout(function() {

  if(typeof(stage) !== "undefined"){
  stage.getRepresentationsByName(message.name).setParameters(message.param);
  }

Shiny.onInputChange(`${message.id}_rendering`, false);

}, 10);
});


Shiny.addCustomMessageHandler('NGLVieweR:updateStage', function(message){

  var stage = getNGLStage(message.id);

Shiny.onInputChange(`${message.id}_rendering`, true);
setTimeout(function() {

  if(typeof(stage) !== "undefined"){
  stage.setParameters(message.param);
 }

 Shiny.onInputChange(`${message.id}_rendering`, false);

}, 10);
});
}
