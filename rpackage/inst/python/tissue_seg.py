# thresholding an image to get the tissue segmented
# Created By Saeed Alahmari, May 26th, 2022  aalahmari.saeed@gmail.com 
# Code updated by Saeed Alahmari, Jan, 24th, 2025 for getting the pixel size automatically from the image scale bar 
# This code aims to segment tissues in micrscopy images, and provide the area of the segmented tissue in microns.
#How to run this code: 
#Type on terminal: python3 tissue_seg.py -imgPath <path2Image> -ResultsPath <path2SaveResults> -cellType NUGC
from calendar import c
#from imp import C_EXTENSION
import os 
import sys 
import cv2 
from PIL import Image
from PIL.TiffTags import TAGS
import numpy as np 
import pandas as pd 
import argparse
from tqdm import tqdm
from get_pixel_size import get_pixel_size

#path2Images = '.'
#path2Images = 'NCI-N87_A59_seedT9_20x_ph_tr.tif'

def fill_holes(image_result):
    im_floodfill = image_result.copy()
    # Mask used to flood filling.
    # Notice the size needs to be 2 pixels than the image.
    h, w = image_result.shape[:2]
    mask = np.zeros((h+2, w+2), np.uint8)
    # Floodfill from point (0, 0)
    #print(image_result[60,60])
    cv2.floodFill(im_floodfill, mask, (60,60), 255,flags=8)
    #plot_image(im_floodfill,'im_floodfill')
    # Invert floodfilled image
    im_floodfill_inv = cv2.bitwise_not(im_floodfill)
    #plot_image(im_floodfill_inv,'imfloodfill_inv')
    # Combine the two images to get the foreground.
    im_out = image_result | im_floodfill_inv
    return im_out

def get_connected_components(image,mask,pixel_size,ImageName,path2SaveResults,saveVis,line_point):
    ImageName = ImageName.split('.')[0]
    #image = cv2.rectangle(image, (100,100), (1900,1200), (0,0,255), 4)
    image = cv2.rectangle(image, (100,100), (mask.shape[1]-100,line_point[1]-100), (0,0,255), 4)
    output = cv2.connectedComponentsWithStats(mask,8,cv2.CV_32S)
    (numlabels,labels,stats,centroids) = output 
    df = pd.DataFrame()
    island_list = []
    area_list = []
    for i in range(0,numlabels):
        if i == 0: #Background
            continue
        x = stats[i,cv2.CC_STAT_LEFT]
        y = stats[i, cv2.CC_STAT_TOP]
        w = stats[i, cv2.CC_STAT_WIDTH]
        h = stats[i, cv2.CC_STAT_HEIGHT]
        area = stats[i, cv2.CC_STAT_AREA]
        if area < 50:
            continue
        (cX,cY) = centroids[i]
        island_list.append(i)

        area_list.append(area * pixel_size * pixel_size)
        
        vis_image = image.copy()
        cv2.rectangle(vis_image,(x,y),(x+w,y+h),(0,255,0),3)
        cv2.circle(vis_image,(int(cX),int(cY)),4,(0,0,255),-1)
        vis_image = cv2.putText(vis_image, 'Area of segmented island in px is '+str(area), (50,50), 3, 
                   1, (0,0,255), 1, cv2.LINE_AA)
        if saveVis:
            cv2.imwrite(os.path.join(path2SaveResults,ImageName+'_island_'+str(i)+'_vis.png'),vis_image)
    df['island_index'] = island_list
    df['Area in um'] = area_list
    df.to_csv(os.path.join(path2SaveResults,ImageName+'.csv'),index=False)


def get_mask(path2Images,path2Results,cellType,saveVis):
    image = cv2.imread(path2Images,-1)
    image = cv2.cvtColor(image,cv2.COLOR_BGR2RGB)
    ImageName = path2Images.split('/')[-1]
    if not os.path.exists(os.path.join(path2Results,'scale_bar')):
        os.makedirs(os.path.join(path2Results,'scale_bar'))
    path2Save = os.path.join(path2Results,'scale_bar')
    #print(ImageName)
    if ImageName == '':
        ImageName = path2Images
    scale_pixels,scale_um,line_point,pixel_size = get_pixel_size(path2Images,path2Save)
    if pixel_size == None:
        print('Error: could not calculate the pixel size. skipping')
        return
    name_no_ext = ImageName.split('.tif')[0]
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray,(3,3),0.5)
    #cv2.imwrite(ImageName+'_blur.png',blur)
    otsu_threshold, image_result = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    #cv2.imwrite(os.path.join(path2Results,ImageName.split('.tif')[0],name_no_ext+'_seg_OTSU.png'),image_result)
    
    mask = np.zeros(blur.shape,np.uint8)
    #mask[100:1200,100:1900] = image_result[100:1200,100:1900]
    mask = image_result[100:line_point[1]-10,100:mask.shape[1]-100] #
    if cellType.startswith('NUGC'):
        #kernel = np.ones((2,2),np.uint8)
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(2,2))
        filled_image = fill_holes(mask)
        mask = cv2.morphologyEx(filled_image, cv2.MORPH_CLOSE, kernel,iterations=11)
        #cv2.imwrite(os.path.join(path2Results,ImageName.split('.tif')[0],name_no_ext+'_closed_mask.png'),mask)
        #cv2.imwrite(os.path.join(path2Results,ImageName.split('.tif')[0],name_no_ext+'_filled_mask.png'),filled_image)
    elif cellType.startswith('KAT'):
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(2,2))
        
        hsv_image = cv2.cvtColor(image,cv2.COLOR_RGB2HSV)
        light_green = (0,50,0)
        dark_green = (175,255,150)  
        mask_res = cv2.inRange(hsv_image, light_green, dark_green)
        #mask[100:1200,100:1900] = mask_res[100:1200,100:1900]
        mask = mask_res[100:line_point[1]-10,100:mask.shape[1]-100] #
        mask = fill_holes(mask)
        #mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel,iterations=5)
        mask = cv2.dilate(mask, kernel, iterations=5)
    else:
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(2,2))
        kernel = np.ones((9,9),np.uint8)
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel,iterations=5)

    #mask[100:1200,100:1900] = image_result[100:1200,100:1900]
    #cv2.imwrite(ImageName+'_seg_OTSU_closed.png',image_result)
    
    #cv2.imwrite(ImageName+'_seg_OTSU_holefilled.png',im_out)
    if not os.path.exists(path2Results):
        os.makedirs(path2Results)
    if not os.path.exists(os.path.join(path2Results,ImageName.split('.')[0])):
        os.makedirs(os.path.join(path2Results,ImageName.split('.')[0]))
    path2SaveResults = os.path.join(path2Results,ImageName.split('.')[0])
    cv2.imwrite(os.path.join(path2SaveResults,ImageName.split('.')[0]+'_mask.png'),mask)
    get_connected_components(image,mask,pixel_size, ImageName,path2SaveResults,saveVis,line_point)
#get_mask(path2Images)


def loopTroughImages(path2Images,path2Results,cellType,saveVis):
    for item in tqdm(os.listdir(path2Images)):
        if not os.path.isfile(os.path.join(path2Images,item)):
            continue
        elif item.startswith('.'):
            continue
        elif not item.startswith(cellType):
            continue
        else:
            get_mask(os.path.join(path2Images,item),path2Results,cellType,saveVis)


def main(parser):
    args = parser.parse_args()
    if os.path.isfile(args.imgPath) and args.imgPath.endswith('.tif'):
        get_mask(args.imgPath,args.resultsPath,args.cellType.upper(),args.saveVis)
    elif os.path.isdir(args.imgPath):
        loopTroughImages(args.imgPath,args.resultsPath,args.cellType.upper(),args.saveVis)
    """ 
    except:
        path2Images = '/Users/saeedalahmari/Downloads/stanford_images/images'
        path2Results = '/Users/saeedalahmari/Downloads/stanford_images/results_tissue-seg'
        cell_line = 'NCI'
        saveVis = True
        if os.path.isfile(path2Images) and path2Images.endswith('.tif'):
            get_mask(path2Images,path2Results,cell_line.upper(),saveVis)
        elif os.path.isdir(path2Images):
            loopTroughImages(path2Images,path2Results,cell_line.upper(),saveVis)
    """
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-imgPath',required=True,help='Path to an image including image name')
    parser.add_argument('-resultsPath',required=False,default='.',help='Path to save the results')
    parser.add_argument('-cellType',required=True,help='name of cell type for the images example NUGC, NCI-N87, SNU, etc')
    parser.add_argument('--saveVis',action='store_true',help='Flag for saving all the visualization for detected tissues, default is False')
    main(parser)

