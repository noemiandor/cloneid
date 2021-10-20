#QC_Statistics.py
# Get variance of Laplician and fft for detecting the image blurness

import sys 
import cv2
import numpy as np 
import pandas as pd 
import os
from tqdm import tqdm 



def variance__of_laplacian(image):
    vl = cv2.Laplacian(image,cv2.CV_64F).var()
    return vl 

def FFT(image):
    (height,width) = image.shape 
    (cX,cY) = (int(width/2.0),int(height/2.0))
    fft = np.fft.fft2(image)
    fftshifted = np.fft.fftshift(fft)
    fftshifted[cY - 40:cY + 40, cX - 40:cX + 40] = 0
    fftshifted = np.fft.ifftshift(fftshifted)
    reconstructed = np.fft.ifft2(fftshifted)
    magnitude = 20 * np.log(np.abs(reconstructed))
    mean = np.mean(magnitude)
    return mean



def QC_Statistics(path2Images,path2Destination,ext):
    if not ext.startswith('.'):
        ext = '.'+ext
    for item in tqdm(os.listdir(path2Images)):
        if item.startswith('.') or not item.endswith(ext):
            continue
        elif item.endswith('_masks'+ext):
            continue
        else:
            filename = item.split(ext)[0]
            image = cv2.imread(os.path.join(path2Images,item))
            image = cv2.cvtColor(image,cv2.COLOR_BGR2GRAY)
            vl = variance__of_laplacian(image)
            fft = FFT(image)
            df = pd.read_csv(os.path.join(path2Destination,filename+'.csv'),sep='\t')
            df['Variance of Laplician'] = vl
            df['fft'] = fft
            df.to_csv(os.path.join(path2Destination,filename+'.csv'),index=False,sep='\t')

'''
if __name__ == "__main__":
    # execute only if run as a script
    args = len(sys.argv)
    if args == 4:       # the arguments are the path2Images, path2Destination, extention of images. 
      QC_Statistics(sys.argv[1],sys.argv[2],sys.argv[3])
    else:
      print('Error in number of arguments')
'''