clearAnnotations();

// import the ABBA atlas alignments and add the detections to the hierarchy
qupath.ext.biop.abba.AtlasTools.loadWarpedAtlasAnnotations(getCurrentImageData(), "acronym", true);
selectDetections();
var imageData = getCurrentImageData()
var pathObjects = getSelectedObjects()

getCurrentHierarchy().insertPathObjects(pathObjects)