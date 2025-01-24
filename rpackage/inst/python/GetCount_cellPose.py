#post-processing prediction

#to run this file do 
#python GetCount_cellPose.py  <path to images>  <path to pretrained model> <path to save results>  <Cell-line name> <extention of the original images such as '.tif'>
import argparse
import os 
import cv2
import numpy as np 
import pandas as pd 
from tqdm import tqdm 
from cellpose.plot import mask_overlay
from PIL import Image
from PIL.TiffTags import TAGS
import tifffile as tifffile
from get_pixel_size import get_pixel_size

import sys
from subprocess import call 

def vis_overlay(path2Masks,path2Save,ext,line_point):
  #parentPath = os.path.dirname(path2Masks)
  if not os.path.exists(os.path.join(path2Save,'vis')):
    os.makedirs(os.path.join(path2Save,'vis'))
  if not ext.startswith('.'):
    ext = '.'+ext
  print('Getting cell visualization ...')
  for item in tqdm(os.listdir(path2Masks)):
    
    if item.startswith('.'):
      continue 
    elif not item.endswith('_masks.png'):
      continue
    else:
      base_name = item.rsplit('_cp_masks',1)[0]
      msk = cv2.imread(os.path.join(path2Masks,item),-1)
      img = cv2.imread(os.path.join(path2Masks,base_name+ext),cv2.IMREAD_COLOR)
      overlay = mask_overlay(img,msk)
      mask = overlay * 0 
      overlay_copy = overlay.copy()
      overlay = img 
      #msk = msk[100:mask.shape[1]-100,100:line_point[0]-10]
      #overlay[100:1200,100:1900] = overlay_copy[100:1200,100:1900]
      overlay[100:line_point[1]-10,100:mask.shape[1]-100] = overlay_copy[100:line_point[1]-10,100:mask.shape[1]-100]
      overlay = cv2.rectangle(overlay, (100,100), (mask.shape[1]-100,line_point[1]-10), (0,0,255), 4)
      cv2.imwrite(os.path.join(path2Save,'vis',base_name+'_overlay.png'),overlay)

def get_blob_prop(msk,pixel_size,path2Image):
  imgray = cv2.imread(path2Image,cv2.IMREAD_GRAYSCALE)
  #cv2.imwrite('image.png',imgray)
  contours,hierarchy = cv2.findContours(msk, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)
  for cnt in contours:
    try:
      m = cv2.moments(cnt)
      x = m['m10']/m['m00']
      x = round(x, 2)
      y = m['m01'] /m['m00']
      y = round(y, 2)
      ROI = 'rectangle'
      area = cv2.contourArea(cnt)
      perimeter = cv2.arcLength(cnt,True)

      area = area * pixel_size * pixel_size
      perimeter = perimeter * pixel_size 
      roundnes_value = (4 * area * 3.1415)/ float(perimeter * perimeter)   # roundness calculated using 4*area*pi/perimeter^2
      # Aspect ratio
      x1,y1,w1,h1 = cv2.boundingRect(cnt)
      x1,y1,w1,h1 =  x1* pixel_size, y1* pixel_size, w1* pixel_size, h1* pixel_size
      aspect_ratio = float(w1)/h1
      # Extent 
      rect_area = w1*h1
      extent = float(area)/rect_area
      # Solidity 
      hull = cv2.convexHull(cnt)
      hull_area = cv2.contourArea(hull)
      hull_area = hull_area* pixel_size * pixel_size
      solidity = float(area)/hull_area
      # Equivalant Diameter 
      equi_diameter = np.sqrt(4*area/np.pi)
      # Orientation Angle and Major Axis and Minor Axis 
      (x,y),(MA,ma),angle = cv2.fitEllipse(cnt)
      MA = MA * pixel_size 
      ma = ma * pixel_size 
      # Mask and Pixel points 
      mask = np.zeros(imgray.shape,np.uint8)
      cv2.drawContours(mask,[cnt],0,255,-1)
      pixelpoints = np.transpose(np.nonzero(mask))
      min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(imgray,mask = mask)
      mean_val = cv2.mean(imgray,mask = mask)
      mean_val = mean_val[0]
    except:
      continue  
    return {'Centroid X µm':x * pixel_size, 'Centroid Y µm':y * pixel_size,'Area µm^2':area,'perimeter µm':perimeter * pixel_size,'roundness':roundnes_value,'ROI':ROI,
            'aspect_ratio':aspect_ratio,'extent':extent,'solidity':solidity,'equi_diameter':equi_diameter,'Major_Axis':ma,'Minor_Axis':MA,'Orientation':angle,'min_val':min_val,'max_val':max_val,'mean_val':mean_val}

def get_ROI_cellCount(df,msk,name,pixel_size):
  df_total_det = pd.DataFrame()
  total_detection = df.shape[0]
  image_name = name.split('_cp_masks')[0]+'.tif'
  [d1,d2] = msk.shape
  area = d1 * d2
  if pixel_size == None:
    df_total_det['Error'] = 'Error in getting the pixel size from the image, skipping ...'
    print('Error in getting the pixel size from the image, skipping ...')
    return df_total_det
  area = area * pixel_size * pixel_size 

  perimeter = d1 + d1 + d2 + d2
  perimeter = perimeter * pixel_size
  Centroid_X = d1/2
  Centroid_X = Centroid_X * pixel_size
  Centroid_Y = d2/2
  Centroid_Y = Centroid_Y * pixel_size
  ROI = 'rectangle'
  df_total_det['Image Name'] = [image_name]
  df_total_det['ROI'] = [ROI]
  df_total_det['Centroid X µm'] = [Centroid_X] 
  df_total_det['Centroid Y µm'] = [Centroid_Y]
  df_total_det['Num Detections'] = [total_detection]
  df_total_det['Area µm^2'] = [area] 
  df_total_det['perimeter µm'] = [perimeter] 
  return df_total_det

def getCount(path2Pred):
  msk_names = []
  count = []
  for msk in os.listdir(path2Pred):
    if not msk.endswith('_masks.png'):
      continue 
    else:
      mask = cv2.imread(os.path.join(path2Pred,msk),-1)
      msk_names.append(msk)
      count.append(mask.max())
  df = pd.DataFrame()
  df['Image'] = msk_names 
  df['count'] = count
  return df

def get_count2csv(list_of_cells_props):
    df = pd.DataFrame()
    df['Centroid X µm'] = [i['Centroid X µm'] for i in list_of_cells_props]
    df['Centroid Y µm'] = [i['Centroid Y µm'] for i in list_of_cells_props]
    df['ROI'] = [i['ROI'] for i in list_of_cells_props]
    df['Area µm^2'] = [i['Area µm^2'] for i in list_of_cells_props]
    df['perimeter µm'] = [i['perimeter µm'] for i in list_of_cells_props]
    df['roundness'] = [i['roundness'] for i in list_of_cells_props]
    df['aspect_ratio'] = [i['aspect_ratio'] for i in list_of_cells_props]
    df['extent'] = [i['extent'] for i in list_of_cells_props]
    df['solidity'] = [i['solidity'] for i in list_of_cells_props]
    df['equi_diameter'] = [i['equi_diameter'] for i in list_of_cells_props]
    df['Major_Axis'] = [i['Major_Axis'] for i in list_of_cells_props]
    df['Minor_Axis'] = [i['Minor_Axis'] for i in list_of_cells_props]
    df['Orientation'] = [i['Orientation'] for i in list_of_cells_props]
    df['min_val'] = [i['min_val'] for i in list_of_cells_props]
    df['max_val'] = [i['max_val'] for i in list_of_cells_props]
    df['mean_val'] = [i['mean_val'] for i in list_of_cells_props]
    return df


def iterate(path2Pred,path2Save,ext):
  #parentPath = os.path.dirname(path2Pred)
  if not os.path.exists(os.path.join(path2Save,'pred')):
    os.makedirs(os.path.join(path2Save,'pred'))
  if not os.path.exists(os.path.join(path2Save,'cellpose_count')):
    os.makedirs(os.path.join(path2Save,'cellpose_count'))
  print('Getting the cell count ... ')
  pixel_size_buffer = [] # this buffer is used to track the pixel sizes, 
                         #if pixel size of None is detected the last element in the buffer is used. 
  for maskName in tqdm(os.listdir(path2Pred)):
      if maskName.startswith('.'):
          continue
      if not maskName.endswith('_cp_masks.png'):
          continue 
      else:
          if not ext.startswith('.'):
            ext = '.'+ext
          mask = cv2.imread(os.path.join(path2Pred,maskName),-1)
          image_name = maskName.split('_cp_masks.png')[0]+ext
          path2Image = os.path.join(path2Pred,image_name)
          #objective_len = get_metadata(path2Image)
          scale_pixels,scale_um,line_point,pixel_size = get_pixel_size(path2Image,path2Save)
          pixel_size_buffer.append(pixel_size)
          # Get pixel size from buffer. 
          if pixel_size is None:
            try:
              pixel_size = pixel_size_buffer[-1]
            except Exception as e:
              print('Error: Could Not Get Pixel Size From Buffer {}'.format(e))
          #print('Pixel size is {}'.format(pixel_size))
          list_of_cells_props = []
          for i in range(mask.max()):
              msk =(mask == i+1)*255
              #msk = msk[100:1200,100:1900]
              msk = msk[100:line_point[1]-10,100:mask.shape[1]-100] #
              nzCount = cv2.countNonZero(msk)
              if(nzCount > 0):
                  prop_dict = get_blob_prop(msk.astype(np.uint8),pixel_size,path2Image)
                  if prop_dict:
                      list_of_cells_props.append(prop_dict)

          df = get_count2csv(list_of_cells_props)
          df_total = get_ROI_cellCount(df,msk,maskName,pixel_size)
          df.to_csv(os.path.join(path2Save,'pred',maskName.split('_cp_masks')[0]+'.csv'),index=False,sep='\t')
          df_total.to_csv(os.path.join(path2Save,'cellpose_count',maskName.split('_cp_masks')[0]+'.csv'),index=False,sep='\t')
          return line_point

def run_cellPose(path2Images,path2Pretrained, diameter, flow, cellprob):
  call(['python', '-m' , 'cellpose' ,'--dir', path2Images ,'--pretrained_model', path2Pretrained,'--use_gpu','--save_png', '--verbose', '--diameter', diameter, '--flow_threshold', flow, '--cellprob_threshold', cellprob])

def run(path2Images,path2Pretrained,path2Save,ext, diameter, flow, cellprob):
  run_cellPose(path2Images,path2Pretrained, diameter, flow, cellprob)
  line_point = iterate(path2Images,path2Save,ext)
  vis_overlay(path2Images,path2Save,ext,line_point)


if __name__ == "__main__":
    #execute only if run as a script
    args = len(sys.argv)
    print(args)
    if args == 6:
      run(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5])
    else:
      print('Error in number of arguments')
    #run('/Users/saeedalahmari/Downloads/stanford_images','../NCI-N87-Iter2_models_best/cellpose_residual_on_style_on_concatenation_off_train_iteration2_2022_10_03_02_31_01.132104','/Users/saeedalahmari/Downloads/stanford_images/results','.tif','30', '0.2', '0.8')
