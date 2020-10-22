# lagosus-reservoir
Data module classifying lakes as natural lakes or reservoirs in the conterminous U.S.
Lake polygons not included here due to file size limitations. All polygons can be found within the LAGOSUS dataset, and are identified by lagoslakeid.

script.py --- Main script used to train both the US and NE models given input lake polygons from the respective manually classified sets. Also contains the scripts used to predict on unclassified lake polygons given trained models.

functions/
    Train.py --- underlying functions used in the script to train the models in script.py
    DataLoading.py --- functions used in organizing and loading lake polygons, given filepath containing the images.
    process_results_nolabel.py --- post prediction processing of model predicted lake polygons, to go from raw model output to formatted table
    process_results_wlabel.py --- post training and validation processing of manually classified lake polygons, to go from raw model output to formatted table
       
