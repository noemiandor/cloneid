# This script segment the scale bar and compute the pixel values.


import tifffile 
import os
import sys
import cv2
import easyocr
import numpy as np
reader = easyocr.Reader(['ch_sim','en']) # this needs to run only once to load the model into memory


#path2Images = '/Users/saeedalahmari/Downloads/images'

def get_image_metadata(image_path):
    with tifffile.TiffFile(os.path.join(image_path, image_name)) as tiff:
        # Check metadata for pixel size
        metadata = tiff.pages[0].tags
        print(metadata)

def get_pixel_size_new(image_path):

    # Load the image
    image = cv2.imread(image_path, cv2.IMREAD_COLOR)
    if image.shape[-1] == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image

    # Apply edge detection
    edges = cv2.Canny(gray, threshold1=150, threshold2=254)
    #cv2.imwrite('canny.png',edges)
    # Detect lines using the Hough Line Transform
    lines = cv2.HoughLinesP(
        edges, 
        rho=1, 
        theta=np.pi / 180, 
        threshold=100, 
        minLineLength=200, 
        maxLineGap=1
    )

    if lines is not None:
        # Filter and draw only horizontal lines
        for line in lines:
            x1, y1, x2, y2 = line[0]
            angle = np.arctan2(y2 - y1, x2 - x1) * 180 / np.pi
            if abs(angle) < 1:  # Horizontal lines have angles close to 0 degrees
                cv2.line(image, (x1, y1), (x2, y2), (0, 255, 0), 2)  # Draw in green
                cv2.imwrite('image_with_line.png',image)
                x1_bb = x1 - 50
                y1_bb = y1 - 50
                x2_bb = x2 + 50
                y2_bb = y2 + 50
                scale_bar_length_in_pixels = x2 - x1 
    else:
        print("No horizontal lines detected!")
        return None,None,None


    # Crop the region around the scale bar to read text
    #text_roi = gray[y_bb + h_bb:y + 2 * h, x - 50:x + w + 50]  # Adjust ROI based on your image layout
    text_roi = gray[y1_bb:y2_bb, x1_bb:x2_bb] # Adjust ROI based on your image layout
    cv2.imwrite('text_roi.png', text_roi)
    scale_output = reader.readtext('text_roi.png')
    scale_text_um = scale_output[0][1].split('U')[0]
    #print("Detected scale text in um:", scale_text_um)
    #print("Detected scale bar length in pixels:",scale_bar_length_in_pixels)
    #Replace O with 0
    if 'O' in scale_text_um:
        scale_text_um = scale_text_um.replace('O','0')
    if 'o' in scale_text_um:
        scale_text_um = scale_text_um.replace('o','0')
    try:
        scale_text_um.replace('O','0')
        pixel_size = int(scale_text_um)/float(scale_bar_length_in_pixels)
    except:
        scale_text_um = scale_text_um.split('u')[0]
        pixel_size = int(scale_text_um)/float(scale_bar_length_in_pixels)

    return scale_bar_length_in_pixels, scale_text_um, pixel_size

''' 
for image_name in os.listdir(path2Images):
    if image_name.startswith('._'):
        continue
    elif not image_name.endswith('.tif'):
        continue
    print(image_name)
    scale_bar_length_in_pixels, scale_text_um, pixel_size = get_pixel_size(os.path.join(path2Images, image_name))
'''

