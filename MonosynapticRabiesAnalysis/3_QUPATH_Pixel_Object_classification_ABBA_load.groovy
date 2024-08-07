// BEFORE RUNNING THIS SCRIPT COPY THE
// CLASSIFYER FOLDER INTO THE QUPATH FOLDER

clearAllObjects();

// perform Pixel and Object classification for mCh+ and GFP+ cells
setImageType('FLUORESCENCE');
createDetectionsFromPixelClassifier("Pixel_mCh+", 5.0, 0.0, "SPLIT")
selectDetections();
addShapeMeasurements("AREA", "LENGTH", "CIRCULARITY", "SOLIDITY", "MAX_DIAMETER", "MIN_DIAMETER", "NUCLEUS_CELL_RATIO")
selectDetections();
runPlugin('qupath.lib.algorithms.IntensityFeaturesPlugin', '{"pixelSizeMicrons":0.6,"region":"ROI","tileSizeMicrons":25.0,"channel1":false,"channel2":true,"channel3":true,"doMean":true,"doStdDev":true,"doMinMax":true,"doMedian":true,"doHaralick":false,"haralickMin":NaN,"haralickMax":NaN,"haralickDistance":1,"haralickBins":32}')
runObjectClassifier("obj_GFP+", "obj_mCh+");

// import the ABBA atlas alignments and add the detections to the hierarchy
qupath.ext.biop.abba.AtlasTools.loadWarpedAtlasAnnotations(getCurrentImageData(), "acronym", true);
selectDetections();
var imageData = getCurrentImageData()
var pathObjects = getSelectedObjects()

getCurrentHierarchy().insertPathObjects(pathObjects)

// Select objects by classification 'GFP+'
selectObjectsByClassification("GFP+");

// Reclassify the selected objects to 'Ignore*'
getSelectedObjects().each {
    it.setPathClass(getPathClass("Ignore*"))
}

// Update the display
fireHierarchyUpdate()