# This script segment the scale bar and compute the pixel values.


import tifffile 
import os
import sys
import cv2
import ssl
import easyocr
import numpy as np
import re
ssl._create_default_https_context = ssl._create_unverified_context
reader = easyocr.Reader(['ch_sim','en']) # this needs to run only once to load the model into memory


#path2Images = '/Users/saeedalahmari/Downloads/images_10x'

def get_image_metadata(image_path):
    with tifffile.TiffFile(os.path.join(image_path, image_name)) as tiff:
        # Check metadata for pixel size
        metadata = tiff.pages[0].tags
        print(metadata)

def process_detected_text(path2Save):
    scale_output = reader.readtext(os.path.join(path2Save,'scalebar','text_roi.png'))
    #print(scale_output[0][1])
    for item in scale_output:
        matches = re.findall(r'\d+\.\d+|\d+', item[1])
        confidence = item[2]
        if len(matches) != 0:
            break # found a match
    return matches,confidence
    
def get_pixel_size(image_path,path2Save):
    if not os.path.exists(os.path.join(path2Save,'scalebar')):
        os.makedirs(os.path.join(path2Save,'scalebar'))
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
        maxLineGap=2
    )

    if lines is not None:
        # Filter and draw only horizontal lines
        length_of_the_line = 0
        for line in lines:
            x1, y1, x2, y2 = line[0]
            angle = np.arctan2(y2 - y1, x2 - x1) * 180 / np.pi
            if abs(angle) < 1:  # Horizontal lines have angles close to 0 degrees
                cv2.line(image, (x1, y1), (x2, y2), (0, 255, 0), 2)  # Draw in green
                cv2.imwrite(os.path.join(path2Save,'scalebar','image_with_line.png'),image)
                len_line = x2 - x1
                if len_line > length_of_the_line:
                    length_of_the_line = len_line
                    #lx,ly,rx,ry = x1,y1,x2,y2
                    x1_bb = max(x1 - 100,0)
                    y1_bb = max(y1 - 100,0)
                    x2_bb = min(x2 + 100,image.shape[1])
                    y2_bb = min(y2 + 100,image.shape[0])
                    scale_bar_length_in_pixels = x2 - x1 
    else:
        print("No horizontal lines detected!")
        return None,None,None

    # Crop the region around the scale bar to read text
    text_roi = gray[y1_bb:y2_bb, x1_bb:x2_bb] # Adjust ROI based on your image layout
    text_roi_scaled = cv2.resize(text_roi, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)
    cv2.imwrite(os.path.join(path2Save,'scalebar','text_roi.png'), text_roi_scaled)

    # Convert the matches to floats (if needed)
    matches,confidence = process_detected_text(path2Save)
    scale_text_um = [float(num) for num in matches]
    if len(scale_text_um) == 0:
        cv2.imwrite(os.path.join(path2Save,'scalebar','text_roi.png'), text_roi)
        matches,confidence = process_detected_text(path2Save)
        scale_text_um = [float(num) for num in matches]
    #print('scale_text_um: {0}'.format(matches))
    if confidence > 0.15:
        pixel_size = float(scale_text_um[0])/float(scale_bar_length_in_pixels)
    else:
        pixel_size = None
    #print('pixel size: {}'.format(pixel_size))
    
    return scale_bar_length_in_pixels, scale_text_um,(x1_bb,y1_bb), pixel_size

''' 
for image_name in os.listdir(path2Images):
    if image_name.startswith('._'):
        continue
    elif not image_name.endswith('.tif'):
        continue
    print(image_name)
    scale_bar_length_in_pixels, scale_text_um,loc, pixel_size = get_pixel_size(os.path.join(path2Images, image_name),'.')
'''

