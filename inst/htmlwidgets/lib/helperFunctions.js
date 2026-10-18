//<------------------------- /addRepresentation/ ------------------------->

//Convert a color object to a color scheme id: a colorByValue() map (an
//object with type "values") or a selection scheme (an array of
//[color, selection] pairs). `structures` (the widget's structure components,
//in structure number order) is needed for value maps. The id is remembered on
//`stage` so releaseColorSchemes() can remove it once no representation uses it.
function colorMaker(color, stage, structures){
 var id;
 if (!Array.isArray(color) && color.type === "values") {
   id = valueScheme(color, structures);
 } else {
   id = NGL.ColormakerRegistry.addSelectionScheme(color);
 }
 if (stage) {
   stage.nglvieweRColorSchemes = (stage.nglvieweRColorSchemes || []).concat(id);
 }
 return id;
}

// A vector of length 1 from R can arrive as a single value
function asArray(x) {
  return Array.isArray(x) ? x : [x];
}

// Registers a color scheme for a colorByValue() map and returns its id. Each
// residue gets the color of its row (by chain, resno and inscode; a row
// without chain matches any chain, a row without structure every structure),
// all other residues na_color.
function valueScheme(map, structures) {
  var structure = asArray(map.structure), chain = asArray(map.chain),
      resno = asArray(map.resno), inscode = asArray(map.inscode),
      color = asArray(map.color);
  var hex = function(c) { return parseInt(c.slice(1), 16); };
  var naColor = hex(map.na_color);

  // Lookup tables for one structure number, built once: rows with a chain
  // by chain, resno and inscode, rows without a chain by resno and inscode.
  // A row for this structure wins over a row for every structure.
  var tables = {};
  function tablesFor(number) {
    if (tables[number]) return tables[number];
    var byChain = {}, anyChain = {};
    for (var i = 0; i < resno.length; i++) {
      if (structure[i] !== null && structure[i] !== number) continue;
      var key = resno[i] + "\n" + inscode[i];
      var table = byChain;
      if (chain[i] === null) table = anyChain; else key = chain[i] + "\n" + key;
      if (!(key in table) || structure[i] !== null) table[key] = hex(color[i]);
    }
    return (tables[number] = { byChain: byChain, anyChain: anyChain });
  }

  var id = NGL.ColormakerRegistry.addScheme(function(params) {
    // Representations pass a view of the structure; find the structure itself
    var s = params.structure;
    if (s && s.getStructure) s = s.getStructure();
    // Number (from 1) of the structure this colormaker colors
    var number = 0;
    (structures || []).forEach(function(c, i) {
      if (c.structure === s) number = i + 1;
    });
    var t = tablesFor(number);
    var cache = {};
    this.atomColor = function(atom) {
      var r = atom.residueIndex;
      if (!(r in cache)) {
        var key = atom.resno + "\n" + (atom.inscode || "");
        var c = t.byChain[atom.chainname + "\n" + key];
        if (c === undefined) c = t.anyChain[key];
        cache[r] = c === undefined ? naColor : c;
      }
      return cache[r];
    };
  }, "colorByValue");
  return id;
}

// Removes the color schemes colorMaker() made for `stage` that none of its
// representations uses any more from NGL's (page-wide) scheme registry.
function releaseColorSchemes(stage) {
  var used = {};
  stage.eachRepresentation(function(r) { used[r.repr.colorScheme] = true; });
  stage.nglvieweRColorSchemes = (stage.nglvieweRColorSchemes || []).filter(function(id) {
    if (used[id]) return true;
    NGL.ColormakerRegistry.removeScheme(id);
    return false;
  });
}

//Apply function over array by key
//Only apply over objects
function arrHandler(arr, key, stage, structures){
  for(var i = 0; i < arr.length; ++i){
    if(typeof arr[i][key] === 'object' && arr[i][key] !== null){
    arr[i][key] = colorMaker(arr[i][key], stage, structures);
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

