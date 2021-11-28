#post-processing prediction

#to run this file do 
#python GetCount_cellPose.py  <path to images>  <path to pretrained model> <path to save results>  <extention of the original images such as '.png'>
import argparse
import os 
import cv2
import numpy as np 
import pandas as pd 
from tqdm import tqdm 
from cellpose.plot import mask_overlay
import sys
from subprocess import call 


def vis_overlay(path2Masks,path2Save,ext):
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
      img = cv2.imread(os.path.join(path2Masks,base_name+ext),-1)
      overlay = mask_overlay(img,msk)
      cv2.imwrite(os.path.join(path2Save,'vis',base_name+'_overlay.png'),overlay)


def get_blob_prop(msk):
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
    except:
      continue  
    return {'Centroid X µm':x, 'Centroid Y µm':y,'Area µm^2':area,'perimeter µm':perimeter,'ROI':ROI}

def get_ROI_cellCount(df,msk,name):
  df_total_det = pd.DataFrame()
  total_detection = df.shape[0]
  image_name = name.split('_cp_masks')[0]+'.tif'
  [d1,d2] = msk.shape
  area = d1 * d2
  perimeter= d1 + d1 + d2 + d2
  Centroid_X = d1/2
  Centroid_Y = d2/2
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
    return df


def iterate(path2Pred,path2Save):
  #parentPath = os.path.dirname(path2Pred)
  if not os.path.exists(os.path.join(path2Save,'pred')):
    os.makedirs(os.path.join(path2Save,'pred'))
  if not os.path.exists(os.path.join(path2Save,'cellpose_count')):
    os.makedirs(os.path.join(path2Save,'cellpose_count'))
  print('Getting the cell count ... ')
  for maskName in tqdm(os.listdir(path2Pred)):
      if maskName.startswith('.'):
        continue
      if not maskName.endswith('_cp_masks.png'):
        continue 
      else:
          mask = cv2.imread(os.path.join(path2Pred,maskName),-1)
          list_of_cells_props = []
          for i in range(mask.max()):
              msk =(mask == i+1)*255
              msk = msk[100:1200,100:1900]
              nzCount = cv2.countNonZero(msk)
              if(nzCount > 0):
                  prop_dict = get_blob_prop(msk.astype(np.uint8))
                  if prop_dict:
                      list_of_cells_props.append(prop_dict)

          df = get_count2csv(list_of_cells_props)
          df_total = get_ROI_cellCount(df,msk,maskName)
          df.to_csv(os.path.join(path2Save,'pred',maskName.split('_cp_masks')[0]+'.csv'),index=False,sep='\t')
          df_total.to_csv(os.path.join(path2Save,'cellpose_count',maskName.split('_cp_masks')[0]+'.csv'),index=False,sep='\t')
          
def run_cellPose(path2Images,path2Pretrained):
  call(['python', '-m' , 'cellpose' ,'--dir', path2Images ,'--pretrained_model', path2Pretrained,'--use_gpu','--save_png'])

def run(path2Images,path2Pretrained,path2Save,ext):
  run_cellPose(path2Images,path2Pretrained)
  iterate(path2Images,path2Save)
  vis_overlay(path2Images,path2Save,ext)

