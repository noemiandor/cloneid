# thresholding an image to get the tissue segmented
# Created By Saeed Alahmari, May 26th, 2022  aalahmari.saeed@gmail.com 
# This code aims to segment tissues in micrscopy images, and provide the area of the segmented tissue in microns.
#How to run this code: 
#Type on terminal: python3 tissue_seg.py -imgPath <path2Image> -ResultsPath <path2SaveResults>
from calendar import c
from imp import C_EXTENSION
import os 
import sys 
import cv2 
from PIL import Image
from PIL.TiffTags import TAGS
import numpy as np 
import pandas as pd 
import argparse

#path2Images = '.'
#path2Images = 'NCI-N87_A59_seedT9_20x_ph_tr.tif'

def fill_holes(image_result):
    im_floodfill = image_result.copy()
    # Mask used to flood filling.
    # Notice the size needs to be 2 pixels than the image.
    h, w = image_result.shape[:2]
    mask = np.zeros((h+2, w+2), np.uint8)
    # Floodfill from point (0, 0)
    cv2.floodFill(im_floodfill, mask, (0,0), 255)
    # Invert floodfilled image
    im_floodfill_inv = cv2.bitwise_not(im_floodfill)
    # Combine the two images to get the foreground.
    im_out = image_result | im_floodfill_inv
    return im_out

def get_connected_components(image,mask,pixel_size,ImageName,path2SaveResults):
    ImageName = ImageName.split('.')[0]
    image = cv2.rectangle(image, (100,100), (1900,1200), (0,0,255), 4)
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
        area_list.append(area * pixel_size)
        vis_image = image.copy()
        cv2.rectangle(vis_image,(x,y),(x+w,y+h),(0,255,0),3)
        cv2.circle(vis_image,(int(cX),int(cY)),4,(0,0,255),-1)
        vis_image = cv2.putText(vis_image, 'Area of segmented island in px is '+str(area), (50,50), 3, 
                   1, (0,0,255), 1, cv2.LINE_AA)
        cv2.imwrite(os.path.join(path2SaveResults,ImageName+'_island_'+str(i)+'_vis.png'),vis_image)
    df['island_index'] = island_list
    df['Area in um'] = area_list
    df.to_csv(os.path.join(path2SaveResults,ImageName+'.csv'),index=False)

def get_metadata(path2Image):
    img = Image.open(path2Image)
    meta_dict = {TAGS[key] : img.tag[key] for key in img.tag_v2}    
    #print(meta_dict)
    try:
        objective_lens = meta_dict['ImageDescription'][0].split(' ')[1]
        objectiveLens = objectiveLens.split('"')[1]
    except:
        if len(path2Image.split('/')) > 1:
            imageName = path2Image.split('/')[-1]
            if '10x' in imageName:
                objective_lens = '10x'
            elif '20x' in imageName:
                objective_lens = '20x'
            elif '40x' in imageName:
                objective_lens = '40x'
        else:
            imageName = path2Image
            if '10x' in imageName:
                objective_lens = '10x'
            elif '20x' in imageName:
                objective_lens = '20x'
            elif '40x' in imageName:
                objective_lens = '40x'
    return objective_lens

def get_mask(path2Images,path2Results):
    image = cv2.imread(path2Images,-1)
    ImageName = path2Images.split('/')[-1]
    if ImageName == '':
        ImageName = path2Images
    objectiveLens = get_metadata(path2Images)
    #objectiveLens = objectiveLens.split('"')[1]
    
    if objectiveLens == '10x':
        pixel_size = 0.922 
    elif objectiveLens == '20x':
        pixel_size = 0.922 / float(2)
    elif objectiveLens == '40x':
        pixel_size = 0.922 / float(4) 
    
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray,(3,3),0.5)
    #cv2.imwrite(ImageName+'_blur.png',blur)
    otsu_threshold, image_result = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    #cv2.imwrite(ImageName+'_seg_OTSU.png',image_result)
    kernel = np.ones((9,9),np.uint8)
    mask = np.zeros(blur.shape,np.uint8)
    image_result = cv2.morphologyEx(image_result, cv2.MORPH_CLOSE, kernel,iterations=5)
    mask[100:1200,100:1900] = image_result[100:1200,100:1900]
    #cv2.imwrite(ImageName+'_seg_OTSU_closed.png',image_result)
    
    #cv2.imwrite(ImageName+'_seg_OTSU_holefilled.png',im_out)
    if not os.path.exists(path2Results):
        os.makedirs(path2Results)
    if not os.path.exists(os.path.join(path2Results,ImageName.split('.')[0])):
        os.makedirs(os.path.join(path2Results,ImageName.split('.')[0]))
    path2SaveResults = os.path.join(path2Results,ImageName.split('.')[0])
    cv2.imwrite(os.path.join(path2SaveResults,ImageName.split('.')[0]+'_mask.png'),mask)
    get_connected_components(image,mask,pixel_size, ImageName,path2SaveResults)
#get_mask(path2Images)


def main(parser):
    args = parser.parse_args()
    get_mask(args.imgPath,args.resultsPath)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('-imgPath',required=True,help='Path to an image including image name')
    parser.add_argument('-resultsPath',required=False,default='.',help='Path to save the results')
    main(parser)
