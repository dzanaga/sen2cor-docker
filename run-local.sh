#!/usr/bin/env bash

# Locations of input folder and desired output
INPUT_FOLDER="/c/Users/ZANAGAD/data/sentinel2/L1C"
OUTPUT_FOLDER="/c/Users/ZANAGAD/data/sentinel2/L2A"

# Basename of the .SAFE container to convert
FILENAME="S2B_MSIL1C_20180802T222539_N0206_R029_T59GPN_20180803T011854.SAFE"

# Sen2Cor auxilliary data location
SEN2COR_HOME="/c/Users/ZANAGAD/data/sen2cor_aux/"

INPUT=$INPUT_FOLDER/$FILENAME

python sen2cor.py $INPUT \
                  -o $OUTPUT_FOLDER \
                  -s $SEN2COR_HOME \
                  --help
