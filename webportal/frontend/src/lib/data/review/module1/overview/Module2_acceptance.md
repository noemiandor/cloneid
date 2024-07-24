---
title: Exhibit A
subtitle: Module 2
section: 2a-b-c
ref: 23-MCC02420
file: Readme.svx
date: 20230902
---

## ACCEPTANCE CRITERIA - CLONEID MODULE 2
---

#### **2a**: The deliverable comprises a web page featuring two distinct panes: the left pane dedicated to the lineage tracing module for phenotypic data, and the right pane dedicated to the multi-omics module for genotypic data.
<br>
<br>
<br>

#### **2b**: In the web page displayed in 2a, phenotypic information is uploaded by dragging a set of images into the drag&drop zone of the lineage tracing module window, which will auto-populate details in the following boxes on the page: id, flask, cellCount, media, tx. ` from` and the `seed/harvest` switch have to be provided by the user. After processing the data, the segmentation masks are presented to the user for review, allowing to assess the quality of the segmentation. Images are displayed with a check-box to exclude any images with incorrect segmentation results. The system calculates the extrapolated cell count for the entire flask using the available non-excluded images. A popup window is displayed, providing a comprehensive summary of the entry, including the newly added information. Segmentation results for uncertified users are temporarily (for just 10 min – 1 hour) saved into specifically dedicated table with the same structure as the Perspective table. For certified users, a popup window prompts them to specify the desired directory where they wish to save the segmentation results.
<br>
<br>
<br>

#### **2c**: In the web page displayed in 2a, genotypic information is uploaded by dragging a folder containing ".spstats" files in the drag&drop zone of the multi-omics module window. The system processes the uploaded data and reports the number of profiles successfully saved. A popup window displays a pie chart of the clonal representation based on the uploaded genotypic information.
<br>


---






