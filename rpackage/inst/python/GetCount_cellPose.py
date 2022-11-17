#post-processing prediction

#to run this file do 
#python GetCount_cellPose.py  <path to images>  <path to pretrained model> <path to save results>  <extention of the original images such as '.tif'>
import argparse
import os 
import cv2
import numpy as np 
import pandas as pd 
from tqdm import tqdm 
from cellpose.plot import mask_overlay
import sys
from subprocess import call 
from PIL import Image
from PIL.TiffTags import TAGS

def get_metadata(path2Image):
    img = Image.open(path2Image)
    meta_dict = {TAGS[key] : img.tag[key] for key in img.tag_v2}    
    #print(meta_dict)
    try:
        objective_lens = meta_dict['ImageDescription'][0].split(' ')[1]
        objective_lens = objective_lens.split('"')[1]
        #print('objectivelens from meta data {}'.format(objective_lens))
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
        #print('objectivelens from filename {}'.format(objective_lens))
    return objective_lens

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


def get_blob_prop(msk,pixel_size):
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
    area = area * pixel_size * pixel_size
    return {'Centroid X µm':x * pixel_size, 'Centroid Y µm':y * pixel_size,'Area µm^2':area,'perimeter µm':perimeter * pixel_size,'ROI':ROI}

def get_ROI_cellCount(df,msk,name,pixel_size):
  df_total_det = pd.DataFrame()
  total_detection = df.shape[0]
  image_name = name.split('_cp_masks')[0]+'.tif'
  [d1,d2] = msk.shape
  area = d1 * d2
  
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
    return df

def get_pixel_size(objectiveLens):
    if objectiveLens == '10x':
        pixel_size = 0.922 
    elif objectiveLens == '20x':
        pixel_size = 0.922 / float(2)
    elif objectiveLens == '40x':
        pixel_size = 0.922 / float(4) 
    return pixel_size


def iterate(path2Pred,path2Save,ext):
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
          if not ext.startswith('.'):
            ext = '.'+ext
          mask = cv2.imread(os.path.join(path2Pred,maskName),-1)
          image_name = maskName.split('_cp_masks.png')[0]+ext
          path2Image = os.path.join(path2Pred,image_name)
          objective_len = get_metadata(path2Image)
          pixel_size = get_pixel_size(objective_len)
          list_of_cells_props = []
          for i in range(mask.max()):
              msk =(mask == i+1)*255
              msk = msk[100:1200,100:1900]
              nzCount = cv2.countNonZero(msk)
              if(nzCount > 0):
                  prop_dict = get_blob_prop(msk.astype(np.uint8),pixel_size)
                  if prop_dict:
                      list_of_cells_props.append(prop_dict)

          df = get_count2csv(list_of_cells_props)
          df_total = get_ROI_cellCount(df,msk,maskName,pixel_size)
          df.to_csv(os.path.join(path2Save,'pred',maskName.split('_cp_masks')[0]+'.csv'),index=False,sep='\t')
          df_total.to_csv(os.path.join(path2Save,'cellpose_count',maskName.split('_cp_masks')[0]+'.csv'),index=False,sep='\t')
          
def run_cellPose(path2Images,path2Pretrained):
  call(['python', '-m' , 'cellpose' ,'--dir', path2Images ,'--pretrained_model', path2Pretrained,'--use_gpu','--save_png', '--verbose', '--diameter', '21', '--flow_threshold', '2.4'])

def run(path2Images,path2Pretrained,path2Save,ext):
  run_cellPose(path2Images,path2Pretrained)
  iterate(path2Images,path2Save,ext)
  vis_overlay(path2Images,path2Save,ext)

'''
if __name__ == "__main__":
    # execute only if run as a script
    args = len(sys.argv)
    print(args)
    if args == 5:
      run(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4])
    else:
      print('Error in number of arguments')
'''
