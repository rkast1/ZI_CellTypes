// ImageJ Macro for Batch Processing TIF Images in Subfolders with Bio-Formats and Saving as Composite PNG

// Choose the main directory containing subfolders with .tiff images
mainDir = getDirectory("Choose the Main Directory");

// Get the list of subfolders
subfolders = getFileList(mainDir);

setBatchMode(true); // Turn on batch mode to prevent windows from popping up

for (j = 0; j < subfolders.length; j++) {
    // Construct the path for the current subfolder
    dir = mainDir + subfolders[j] + File.separator;

    // Get the list of files in the current subfolder
    list = getFileList(dir);

    for (i = 0; i < list.length; i++) {
        // Check if the file is a .tiff image
        if (endsWith(list[i], ".tiff")) {
            print("Processing image: " + list[i]);
            
            // Open image using Bio-Formats
            open_image = "open=[" + dir + list[i] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"  + 4;
            run("Bio-Formats Importer", open_image);
			title = getTitle();
			run("Split Channels");
			c1Title = "C1-" + title;
			c2Title = "C2-" + title;
			c3Title = "C3-" + title;
			selectWindow(c1Title);
			run("Enhance Contrast", "saturated=0.35");
			selectWindow(c2Title);
			run("Enhance Contrast", "saturated=0.35");
			selectWindow(c3Title);
			run("Enhance Contrast", "saturated=0.35");

			run("Merge Channels...", "c1=[" + c2Title + "] c2=[" + c3Title + "] c5=[" + c1Title + "] create");

            // Save the processed image as Composite PNG in the same location
            saveAs("PNG", dir + list[i]);

            // Close the image
            close();
        }
    }
}

setBatchMode(false); // Turn off batch mode

    		