import qupath.lib.roi.EllipseROI;
import qupath.lib.objects.PathDetectionObject
import qupath.lib.gui.commands.Commands;

points = getAnnotationObjects().findAll{it.getROI().isPoint()&& it.getPathClass() == getPathClass("correction_mCh+")}
print points[0].getROI()

describe(points[0].getROI())
//Cycle through each points object (which is a collection of points)
points.each{ 
    //Cycle through all points within a points object
    pathClass = it.getPathClass()
    it.getROI().getAllPoints().each{ 
        //for each point, create a circle on top of it that is "size" pixels in diameter
        x = it.getX()
        y = it.getY()
        size = 5
        def roi = ROIs.createEllipseROI(x-size/2,y-size/2,size,size, ImagePlane.getDefaultPlane())
        
        def aCell = new PathDetectionObject(roi, getPathClass('mCh+'))
        addObject(aCell)
    }
}
//remove points if desired.
removeObjects(points, true)
fireHierarchyUpdate()

ImageData imageData = getCurrentImageData();
selectObjectsByClassification("mCh+");
Commands.insertSelectedObjectsInHierarchy(imageData)
