// The structure component a proxy message targets with `structure` (counting
// from 1): null when none is given, undefined (with a console error) when the
// number is out of range.
function structureFromMessage(message, structures, caller) {
  if (message.structure === undefined || message.structure === null) return null;
  var component = structures[message.structure - 1];
  if (!component) {
    console.error("NGLVieweR: " + caller + "() structure " + message.structure +
      " is out of range: there are " + structures.length + " structures.");
  }
  return component;
}

// Moves the camera to the center/zoom of a selection in a structure
// component (opts: center, zoom, duration, z_offSet). Used by zoomMove() and
// updateZoomMove().
function zoomMoveTo(stage, component, opts) {
  var center = component.getCenter(opts.center);
  var zoom = component.getZoom(opts.zoom) + (opts.z_offSet || 0);
  stage.animationControls.zoomMove(center, zoom, opts.duration || 0);
}

HTMLWidgets.widget({

  name: 'NGLVieweR',

  type: 'output',

  factory: function(el, width, height) {

      var stage = new NGL.Stage(el);
      var structures = null;
      // Options of the latest render, read by the event handlers below
      var currentOpts = null;
      // Number of renders so far; see renderValue
      var renderCount = 0;
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
        } else if (stage.pendingSnapshots > 0) {
          // A snapshot reports the end of rendering itself, after its download
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
          // Number of the clicked structure (from 1), for structure = in
          // addSelection()/updateZoomMove()
          // Clicks are sent as events, so a click that gives the same values
          // as the previous one (e.g. the same residue in another copy of
          // the structure) still triggers observers
          var clicked = structures ? structures.indexOf(pickingProxy.component) + 1 : 0;
          Shiny.onInputChange(`${el.id}_selectionStructure`, clicked > 0 ? clicked : null,
            { priority: "event" });

          // Get AA selection details
          Shiny.onInputChange(`${el.id}_selection`, pickingProxy.getLabel(), { priority: "event" });

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
            Shiny.onInputChange(`${el.id}_selAround`, atomSet2.toSeleString(), { priority: "event" });
          }
        }
      });
     }

    //<---------------------------------// // ------------------------------------------>

    return {
      renderValue: function(opts) {

      currentOpts = opts;
      // Identifies this render, so a slower earlier render that finishes
      // later cannot overwrite or clear it
      var renderId = ++renderCount;

      //In case of Rerendering remove all components
      stage.removeAllComponents();
      releaseColorSchemes(stage);
      structures = null;
      if (HTMLWidgets.shinyMode) {
        // The clicked structure no longer exists
        Shiny.onInputChange(`${el.id}_selectionStructure`, null);
      }

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
      
      // Iterate through all structures in the list. Wait for every load to
      // finish (succeeded or failed), so a failure cannot be followed by a
      // slower structure still appearing.
        Promise.all(opts.structures.map(function(structureOpts, index) {
          // Promise.resolve().then() also turns errors that loadFile() throws
          // straight away into a rejection
          return Promise.resolve().then(function() {
            if (structureOpts.type == "code") {
              // A PDB code: if the .pdb fails (RCSB has none for large
              // entries), load the mmCIF fallback
              return stage.loadFile(structureOpts.data).catch(function(err) {
                if (!structureOpts.fallback) throw err;
                return stage.loadFile(structureOpts.fallback);
              });
            } else if (structureOpts.type == "file") {
              return stage.loadFile(new Blob([structureOpts.data], { type: 'text/plain' }), {
               ext: structureOpts.file_ext
              });
            }
          }).then(function(component) {
            if (!component) {
              throw new Error("nothing was loaded");
            }
            if (component.structure && component.structure.atomCount === 0) {
              throw new Error("it contains no atoms (is the format right?)");
            }
            return { value: component };
          }).catch(function(err) {
            var source = structureOpts.type == "code" ?
              structureOpts.data + (structureOpts.fallback ? " or " + structureOpts.fallback : "") :
              "file contents, format \"" + structureOpts.file_ext + "\"";
            return { error: "could not load structure " + (index + 1) + " (" + source + "): " +
              (err && err.message ? err.message : String(err)) };
          });
        })).then(function(results) {
          var errors = results.filter(function(r) { return r.error; })
            .map(function(r) { return r.error; });
          var loaded = results.filter(function(r) { return r.value; })
            .map(function(r) { return r.value; });
          if (errors.length > 0) {
            loaded.forEach(function(c) { stage.removeComponent(c); });
            var loadError = new Error(errors.join("; "));
            loadError.loadFailure = true;
            throw loadError;
          }
          return loaded;
        }).then(function(loaded) {

          // A newer render has started; drop this one's components
          if (renderId !== renderCount) {
            loaded.forEach(function(c) { stage.removeComponent(c); });
            return;
          }

          // Make globaly available
          structures = loaded;
          
          // Initialize arrays to collect data and send to Shiny
          var sequences = [];
          var resnos = [];
          var chainnames = [];
          var PDBdatas = [];
          // One entry per residue of every structure, sent as columns and
          // turned into a data frame in R (see .residues_input)
          var residues = { structure: [], chain: [], resno: [], inscode: [],
                           resname: [], letter: [] };

          structures.forEach(function(o, index) {
            var structureOpts = opts.structures[index];

            // Load representation inputs
            var representation = structureOpts.addRepresentation;
            var arrType = representation.type;
            var arrValues = representation.values;
            arrHandler(arrValues, "color", stage, structures);

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
 
            // If in Shiny mode, collect AA sequences and other data
            if (HTMLWidgets.shinyMode) {
              var sequence = [];
              var resno = [];
              var chainname = [];
              o.structure.eachResidue(rp => {
                var code = rp.getResname1(); // The single-letter code
                residues.structure.push(index + 1);
                residues.chain.push(rp.chainname);
                residues.resno.push(rp.resno);
                residues.inscode.push(rp.inscode || "");
                residues.resname.push(rp.resname);
                residues.letter.push(code);
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
              Shiny.onInputChange(`${el.id}_residues:NGLVieweR.residues`, residues);
              Shiny.onInputChange(`${el.id}_error`, null);
            }

          // zoomMove last: after superpose (so the center uses the superposed
          // atom coordinates) and after autoView (so nothing moves the camera
          // away again), and after the inputs were sent (so a bad selection
          // does not stop them). If several structures have a zoomMove, the
          // last one is used.
          for (var z = structures.length - 1; z >= 0; z--) {
            var zoomMoveOpts = opts.structures[z].zoomMove;
            if (zoomMoveOpts && typeof zoomMoveOpts.zoom !== 'undefined') {
              zoomMoveTo(stage, structures[z], zoomMoveOpts);
              break;
            }
          }

        }).catch(function(err) {
          if (renderId !== renderCount) return;

          var message = err && err.message ? err.message : String(err);
          if (err && err.loadFailure) {
            // Show nothing rather than part of the structures
            stage.removeAllComponents();
            structures = null;
            if (HTMLWidgets.shinyMode) {
              Shiny.onInputChange(`${el.id}_PDB`, null);
              Shiny.onInputChange(`${el.id}_sequence`, null);
              Shiny.onInputChange(`${el.id}_resno`, null);
              Shiny.onInputChange(`${el.id}_chainname`, null);
              Shiny.onInputChange(`${el.id}_residues`, null);
            }
          } else {
            // The structures loaded, but setting them up failed (e.g. an
            // unknown representation type); keep what is shown, but free
            // color schemes of representations that were not added
            releaseColorSchemes(stage);
            message = "error while displaying the structures: " + message;
          }
          console.error("NGLVieweR: " + message);
          if (HTMLWidgets.shinyMode) {
            Shiny.onInputChange(`${el.id}_error`, message, { priority: "event" });
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
  var stage = getNGLStage(message.id);

  if(typeof(stage) === "undefined"){
    Shiny.onInputChange(`${message.id}_rendering`, false);
    return;
  }

  // makeImage() is asynchronous and NGL's task counter reaches zero just
  // before the image is returned. Count running snapshots on the stage, so
  // the countChanged handler leaves the end of rendering to this handler,
  // which reports it after the download (and only if nothing else runs).
  stage.pendingSnapshots = (stage.pendingSnapshots || 0) + 1;
  Shiny.onInputChange(`${message.id}_rendering`, true);

  var errorMessage = function (err) { return err && err.message ? err.message : String(err); };

  setTimeout(function() {
    stage.makeImage(message.param).then(function (blob) {
      try {
        NGL.download(blob, message.fileName);
      } catch (err) {
        console.error("NGLVieweR: snapshot download failed: " + errorMessage(err));
      }
    }, function (err) {
      console.error("NGLVieweR: snapshot failed: " + errorMessage(err));
    }).then(function () {
      stage.pendingSnapshots--;
      if (stage.pendingSnapshots === 0 && stage.tasks.count === 0) {
        Shiny.onInputChange(`${message.id}_rendering`, false);
      }
    });
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
    // toggleFullscreen() flips the state, so only call it when the current
    // state differs from the requested one
    var fullscreenElement = document.fullscreenElement || document.webkitFullscreenElement ||
      document.mozFullScreenElement || document.msFullscreenElement;
    if (!!message.fullscreen !== !!fullscreenElement) {
      if (message.fullscreen) {
        stage.toggleFullscreen(message.element === "viewer" ? stage.viewer.container : document.body);
      } else {
        // Leave with the element NGL entered with, so it restores that element's size
        stage.toggleFullscreen(stage.lastFullscreenElement || fullscreenElement);
      }
    }
  }

});

Shiny.addCustomMessageHandler('NGLVieweR:updateZoomMove', function(message) {
  
  // Get the array of loaded structures
  var structures = getNGLStructure(message.id);
  var stage = getNGLStage(message.id);

  // Check if structures are loaded and stage is defined
  if (structures && structures.length > 0 && stage) {
    var target = structureFromMessage(message, structures, "updateZoomMove");
    if (target === null) {
      // No structure given; default to the first structure
      zoomMoveTo(stage, structures[0], message);
    } else if (target) {
      zoomMoveTo(stage, target, message);
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
  releaseColorSchemes(stage);
 }

});

Shiny.addCustomMessageHandler('NGLVieweR:addSelection', function(message) {

  // Get the array of loaded structures
  var stage = getNGLStage(message.id);
  var structures = getNGLStructure(message.id);

  // Check if structures are loaded
  if (structures && structures.length > 0) {

    // Prepare the representation parameters
    var param = message.param;
    var color = param['color'];

    // Convert color if necessary
    if (typeof color === 'object' && color !== null) {
      param['color'] = colorMaker(param['color'], stage, structures);
    }

    var target = structureFromMessage(message, structures, "addSelection");
    if (target === null) {
      // No structure given; add to all structures
      structures.forEach(function(o) {
        o.addRepresentation(message.type, param);
      });
    } else if (target) {
      target.addRepresentation(message.type, param);
    }
    // Frees the color scheme if no representation was added
    releaseColorSchemes(stage);

  } else {
    console.log("Structures not loaded or unavailable.");
  }
});

Shiny.addCustomMessageHandler('NGLVieweR:updateColor', function(message){

  var stage = getNGLStage(message.id);
  var color = message.color;

Shiny.onInputChange(`${message.id}_rendering`, true);
setTimeout(function() {


  if(typeof(stage) !== "undefined"){
  if(typeof color === 'object' && color !== null){
    color = colorMaker(color, stage, getNGLStructure(message.id));
  }
  stage.getRepresentationsByName(message.name).setColor(color);
  releaseColorSchemes(stage);
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

Shiny.onInputChange(`${message.id}_rendering`, true);
setTimeout(function() {

  if(typeof(stage) !== "undefined"){
  //Convert color values. Registered here, right before it is used, so a
  //releaseColorSchemes() in between cannot remove the new scheme.
  if(typeof color === 'object' && color !== null){
    param['color'] = colorMaker(color, stage, getNGLStructure(message.id));
  }
  stage.getRepresentationsByName(message.name).setParameters(message.param);
  releaseColorSchemes(stage);
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
