#!/usr/bin/env bash

SEN2COR_HOME="/root/sen2cor/2.5"
SEN2COR_BIN="/sen2cor/Sen2Cor-02.05.05-Linux64/lib/python2.7/site-packages/sen2cor"
FILENAME="S2B_MSIL1C_20180802T222539_N0206_R029_T59GPN_20180803T011854.SAFE"
INPUT="/c/Users/ZANAGAD/data/sentinel2/L1C/${FILENAME}"
INPUT_FOLDER="/c/Users/ZANAGAD/data/sentinel2/L1C"

AUX_DATA="/c/Users/ZANAGAD/Downloads/CCI/aux_data"
DEM_DATA="/c/Users/ZANAGAD/Downloads/CCI/dem"
LOG_DATA="/c/Users/ZANAGAD/Downloads/CCI/log"

OUTPUT="/c/Users/ZANAGAD/data/sentinel2/L2A"



# docker run --rm -it -v ${INPUT_FOLDER}:"/sen2cor/input" \
#                     -v ${AUX_DATA}:"${SEN2COR_BIN}/aux_data" \
#                     -v ${DEM_DATA}:"${SEN2COR_HOME}/dem" \
#                     -v ${LOG_DATA}:"${SEN2COR_HOME}/log" \
#                     redblanket/sen2cor:latest "input/${FILENAME}" --resolution 60

./sen2cor.py -o ${OUTPUT} -a ${AUX_DATA} -d ${DEM_DATA} -l ${LOG_DATA} ${INPUT}
