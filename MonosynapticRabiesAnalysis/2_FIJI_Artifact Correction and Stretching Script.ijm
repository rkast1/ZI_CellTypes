// ImageJ Macro for Batch Processing TIF Images with Bio-Formats

// Choose the directory with the .tiff images
dir = getDirectory("Choose a Directory of TIF Images");
out_dir = getDirectory("Choose a Output Directory for Corrected TIF Images");
list = getFileList(dir);
series = 2
setBatchMode(true); // Turn on batch mode to prevent windows from popping up

for (i = 0; i < list.length; i++) {
    // Check if the file is a .tiff image
    if (endsWith(list[i], ".tiff")) {
        // Check if the image already exists in the output folder
        if (File.exists(out_dir + list[i])) {
            print("Image already processed: " + list[i]);
            continue; // Skip this image
        }
        processImage = true;
        print("Processing image: " + list[i]);

        while (processImage) {
            // Open image using Bio-Formats
            open_image = "open=[" + dir + list[i] + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + series;

    		run("Bio-Formats Importer", open_image);

//			run("Size...", "width="+( getWidth() / 2 )+" constrain average interpolation=Bicubic");
			Stack.setXUnit("micron");
			run("Properties...", "channels=3 slices=1 frames=1 pixel_width=0.6755958 pixel_height=0.6756081 voxel_depth=1");
            // Show the image to the user before splitting
            run("Rotate... ", "angle=180 grid=1 interpolation=Bilinear stack");
            setBatchMode(false); // Turn off batch mode for user interaction
            imageID = getImageID();
            selectImage(imageID);

            // Get the title of the selected image
            title = getTitle();
            
            //implement:
			run("Multiply...", "value=4 stack");
//			run("Apply LUT");
            
            // Ask the user if the image needs to be processed
            Dialog.create("Process this image?");
            Dialog.addMessage("Do you want to process the image: " + title + "?");
            Dialog.addCheckbox("Process_Image", false);
            Dialog.show();
            process = Dialog.getCheckbox();
            
            // If the user chooses not to process the image, continue to the next one
            if (!process) {
                saveAs("Tiff", out_dir + list[i]);
                close(); // Close the current image
                break; // Exit the while loop
            }
            
            // Ask the user if they want to rotate the entire image
            Dialog.create("Rotate Entire Image?");
            Dialog.addMessage("Do you want to rotate the entire image?");
            Dialog.addCheckbox("Rotate_Image", false);
            Dialog.show();
            rotateImage = Dialog.getCheckbox();

            if (rotateImage) {
			    entireImageRotationAngle = getNumber("Enter the rotation angle for the entire image (in degrees):", 0);
			    run("Split Channels");
			    c1Title = "C1-" + title;
			    c2Title = "C2-" + title;
			    c3Title = "C3-" + title;
			    selectWindow(c1Title);
			    run("Rotate... ", "angle=" + entireImageRotationAngle);
			    selectWindow(c2Title);
			    run("Rotate... ", "angle=" + entireImageRotationAngle);
			    selectWindow(c3Title);
			    run("Rotate... ", "angle=" + entireImageRotationAngle);
			    run("Merge Channels...", "c1=[" + c1Title + "] c2=[" + c2Title + "] c3=[" + c3Title + "] create");
				Property.set("CompositeProjection", "null");
				Stack.setDisplayMode("grayscale");
				run("Grays");
	            run("Next Slice [>]");
	            run("Grays");
	            run("Next Slice [>]");

            }
			// New section for horizontal flipping
            Dialog.create("Flip Image Horizontally?");
            Dialog.addMessage("Do you want to flip the image to put the more posterior side on the right?");
            Dialog.addCheckbox("Flip_Horizontally", false);
            Dialog.show();
            flipHorizontally = Dialog.getCheckbox();

            if (flipHorizontally) {
                run("Flip Horizontally", "stack");
            }
			
				run("Grays");
			    // Ask user if they want to continue processing
			    Dialog.create("Continue Processing?");
			    Dialog.addMessage("Do you want to continue processing the image?");
			    Dialog.addCheckbox("Continue_Processing", true);
			    Dialog.show();
			    continueProcessing = Dialog.getCheckbox();
			
			    if (!continueProcessing) {
			        // Save the image and exit the while loop
			        saveAs("Tiff", out_dir + list[i]);
			        close("*");
			        processImage = false;
			        continue; // Skip to the next image
			    }
			
			run("Split Channels");
			run("Grays", "stack");
			// Define titles for each channel after splitting
			c1Title = "C1-" + title;
			c2Title = "C2-" + title;
			c3Title = "C3-" + title;

			// Ask the user how many ROIs they want to delete
			numDeleteROIs = getNumber("Enter the number of ROIs to be deleted:", 0);
			
            // Automatically select the freehand tool
            setTool("freehand");

			for (roiDelIndex = 0; roiDelIndex < numDeleteROIs; roiDelIndex++) {
			    waitForUser("Draw ROI " + (roiDelIndex + 1) + " to be deleted using the freehand tool, then add it to the ROI manager by pressing 't'. Press OK when done.");
			    roiManager("Select", 0);
			    
			    for (j = 0; j < nImages; j++) {
                    selectImage(j+1);
                    title = getTitle();
					roiManager("Select", 0);
                    // Set background color to black and clear the ROI
					setBackgroundColor(0, 0, 0);
					run("Clear", "stack");
			    }
			    roiManager("Delete");
			}
			
			// Ask how many ROIs the user wants to rotate
            numROIs = getNumber("Enter the number of ROIs to be rotated:", 0);
            
            for (rotroiIndex = 0; rotroiIndex < numROIs; rotroiIndex++) {
                // Instructions for the user
                waitForUser("Draw ROI " + (rotroiIndex+1) + " using the freehand tool, then add it to the ROI manager by pressing 't'. Press OK when done.");
                rotationAngle = getNumber("Enter the rotation angle for ROI " + (rotroiIndex+1) + " (in degrees):", 0);

                for (j = 0; j < nImages; j++) {
                    selectImage(j+1);
                    title = getTitle();
                    roiManager("Select", rotroiIndex*2); // Select the original ROI
                    if (rotationAngle != 0) {
                        // If a rotation angle was specified, rotate the ROI
                        run("Rotate... ", "angle=" + rotationAngle);
                    }
                }
                roiManager("Delete");
            }
            // Ask how many ROIs the user wants to create and move
            numROIs = getNumber("Enter the number of ROIs to be created and moved:", 0);
            
            for (roiIndex = 0; roiIndex < numROIs; roiIndex++) {
                // Instructions for the user
                waitForUser("Draw ROI " + (roiIndex+1) + " using the freehand tool, then add it to the ROI manager by pressing 't'. Move the ROI to the desired position and register again with 't'. Press OK when done.");
                rotationAngle = getNumber("Enter the rotation angle for ROI " + (roiIndex+1) + " (in degrees):", 0);

                for (j = 0; j < nImages; j++) {
                    selectImage(j+1);
                    title = getTitle();

                    roiManager("Select", 0); // Select the original ROI
                    run("Cut");
                    roiManager("Select", 1); // Select the moved ROI
                    run("Paste");
                    if (rotationAngle != 0) {
                        // If a rotation angle was specified, rotate the ROI
                        run("Rotate... ", "angle=" + rotationAngle);
                    }
                }
                roiManager("Delete");
                roiManager("Delete");
            }

            run("Merge Channels...", "c1=[" + c1Title + "] c2=[" + c2Title + "] c3=[" + c3Title + "] create");
            run("Grays");
            run("Next Slice [>]");
            run("Grays");
            run("Next Slice [>]");
            run("Grays");
			Property.set("CompositeProjection", "null");
			Stack.setDisplayMode("grayscale");
            // Ask user if the processing was satisfactory
            Dialog.create("Image processing satisfactory?");
            Dialog.addMessage("Is the processing of the image " + title + " satisfactory?");
            Dialog.addCheckbox("Satisfactory_Processing", false);
            Dialog.show();
            satisfactory = Dialog.getCheckbox();
            
            if (satisfactory) {
                // Save the image if processing is satisfactory
                saveAs("Tiff", out_dir + list[i]);
                close("*");
                processImage = false; // Exit the while loop
            } else {
                // Close and reprocess the image if not satisfactory
                close("*");
                processImage = true; // Continue the while loop
        	}
    	}
	}
}
print("done");
setBatchMode(false); // Turn off batch mode at the end