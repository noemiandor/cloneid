
import sys
import os 
import cv2 as cv
import numpy as np

# To call this code do brightnessCorrection.py  <PATH FOR IMAGE INCLUDING IMAGE NAME>


def gammaCorrection(img_original):
    gamma = 0.4
    lookUpTable = np.empty((1,256), np.uint8)
    for i in range(256):
        lookUpTable[0,i] = np.clip(pow(i / 255.0, gamma) * 255.0, 0, 255)

    res = cv.LUT(img_original, lookUpTable)
    return res

def ApplyGammaCorrection(imgName):
    img = cv.imread(imgName)
    if img is None:
        print('image reading is not right')
        sys.exit()
    else:
        if np.mean(img) < 20:
            res = gammaCorrection(img)
            cv.imwrite(imgName,res)
            

def main():
    args = len(sys.argv)
    if args < 2:
        print("Error: enter image path including its name")
    else:
        ApplyGammaCorrection(sys.argv[1])
        print('Path is ApplyGammaCorrection')

if __name__ == "__main__":
    main()