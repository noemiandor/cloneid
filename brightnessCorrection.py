
import sys
import os 
import cv2 as cv
import numpy as np
from tqdm import tqdm
import ntpath

# To call this code do brightnessCorrection.py  <PATH FOR IMAGE INCLUDING IMAGE NAME>    <darkness threshold default value is 20>


def equalize_img(img):
    if (len(img.shape)< 3):
        img_eq = cv.equalizeHist(img)
    else:
        R,G,B = cv.split(img)
        R_eq = cv.equalizeHist(R)
        G_eq = cv.equalizeHist(G)
        B_eq = cv.equalizeHist(B)

        img_eq = cv.merge((R_eq,G_eq,B_eq))
        return img_eq

def gammaCorrection(img_original):
    gamma = 0.4
    lookUpTable = np.empty((1,256), np.uint8)
    for i in range(256):
        lookUpTable[0,i] = np.clip(pow(i / 255.0, gamma) * 255.0, 0, 255)

    res = cv.LUT(img_original, lookUpTable)
    return res

def ApplyGammaCorrection(path2Image,th=40):
    if not isinstance(th,int):
        th=int(th)
    img = cv.imread(os.path.join(path2Image))
    if img is None:
        print('image reading is not right')
        sys.exit()
    else:
        imgName=ntpath.basename(path2Image)
        print(np.mean(img))
        if np.mean(img) < th:
            if not imgName.startswith('NCI'):
                img = gammaCorrection(img)
                img = equalize_img(img)   
                img = cv.GaussianBlur(img,(5,5),0) 
            if imgName.startswith('NCI'):
                img = gammaCorrection(img)
                img = np.invert(img)
        cv.imwrite(os.path.join(path2Image),img)

def GetImageNames(pathToImages,th=40):
    images = os.listdir(pathToImages)
    for img in tqdm(images):
        if img.startswith('.'):
            continue
        else:
            ApplyGammaCorrection(pathToImages,img,th)

def main():
    args = len(sys.argv)
    if args < 2:
        print("Error: enter image path including its name")
    if args < 3:
        ApplyGammaCorrection(sys.argv[1])
        print('Path is ApplyGammaCorrection 2 < 3')
    else:
        ApplyGammaCorrection(sys.argv[1],sys.argv[2])
        print('Path is ApplyGammaCorrection 3 or more')

if __name__ == "__main__":
    main()