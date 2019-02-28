#!/usr/bin/env bash

# Basename of the .SAFE container to convert
FILENAME="S2B_MSIL1C_20180429T105619_N0206_R094_T30TXP_20180429T131138.SAFE"

# Locations of input folder and desired output
INPUT_FOLDER="/data/cel_vol1/HRL_PHENO/S2/S2_TOA/30TXP"
OUTPUT_FOLDER="/data/cel_vol1/HRL_PHENO/S2/S2_TOC/30TXP"

# Sen2Cor auxilliary data location
S2C_AUX="/data/cel_vol1/HRL_PHENO/SEN2COR"

# Sen2cor auxilliary data
AUX_DATA="${S2C_AUX}/aux_data"
DEM_DATA="${S2C_AUX}/dem"
LOG_DATA="${S2C_AUX}/log/${FILENAME}"

# create output folders
mkdir ${LOG_DATA} ${OUTPUT_FOLDER}

# Inner sen2cor docker folders
SEN2COR_HOME="/root/sen2cor/2.5"
SEN2COR_BIN="/tmp/sen2cor/Sen2Cor-02.05.05-Linux64/lib/python2.7/site-packages/sen2cor"
CONTAINER_INPUT="/tmp/input"

# Add sen2cor options, e.g. "--resolution 60" here, before the filename
# INPUT_COMMAND="--resolution 60 ${CONTAINER_INPUT}/${FILENAME}"
INPUT_COMMAND="${CONTAINER_INPUT}/${FILENAME}"

# Run docker container
docker run --rm -it -v ${INPUT_FOLDER}:"/tmp/input" \
                    -v ${OUTPUT_FOLDER}:"/tmp/output" \
                    -v ${AUX_DATA}:"${SEN2COR_BIN}/aux_data" \
                    -v ${DEM_DATA}:"${SEN2COR_HOME}/dem" \
                    -v ${LOG_DATA}:"${SEN2COR_HOME}/log" \
                    -e HOSTUSER_ID=`id -u` \
                    redblanket/sen2cor:latest ${INPUT_COMMAND}
