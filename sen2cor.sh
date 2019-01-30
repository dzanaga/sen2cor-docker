#!/bin/bash
# Command script for Sen2Cor atmospheric correction package [dockerized]
# To install make the script executable  and place it in a folder in the
# path, such as /usr/local/bin if you have admin rights. Otherwise execute the
# script from its location, or put its location in the PATH.
# N.B. Docker daemon needs to be installed and running.

# Help instructions
function usage()
{
    printf "\nCommand script for Sen2Cor atmospheric correction package [dockerized].\n"
    printf "Example usage: ./sen2cor [-h|--help] [-r|--resolution {10,20,60}] [-O|--output-folder] S2B_MSIL1C_SCENE-ID.SAFE\n\n"
    printf "Parameters:\n"
    printf "  -h --help\t\tHelp \n"
    printf "  -r --resolution\tTarget resolution, can be 10, 20 or 60. OPTIONAL: default all resolutions will be processed\n"
    printf "  -O --output-folder\tSpecify output folder. OPTIONAL: default will be input data folder\n\n"
}

# Will check if output path is absolute or relative
function check_path()
{
  initial="$(echo $1 | head -c 1)"
  if [ "$initial" = "/" ]; then
    is_absolute=true
  else
    is_absolute=false
  fi
}

# Will check and eventually create output folder
function check_dir_exists()
{
  if [ ! -d "$1" ]; then
    mkdir -p $1
  fi
}

# Ensure input resolution value is acceptable
function check_resolution()
{
  if [ ! -z "$1" ]; then # RESOLUTION is not empty value
    if [ "$1" -ne 10 -a "$1" -ne 20 -a "$1" -ne 60 ]; then
      printf "Wrong resolution value. Target resolution can be 10, 20 or 60m (default all). Exiting...\n"
      exit
    fi
  fi
}

# function get_l2a_filename()
# {
#   L1C_FILENAME=$1
#   L2A_PREFIX="S2B_MSIL2A_"
#   L2A_FILENAME=${$L1C_FILENAME: ${#L2A_PREFIX}:${#L1C_FILENAME}}
# }

# Parameters parser
PARAMS=""
while (( "$#" )); do
  case "$1" in
        -h|--help)
            usage
            exit
            ;;
        -r|--resolution)
            RESOLUTION="$2"
            PARAMS="--resolution $2 "
            shift 2
            ;;
        -O|--output-folder)
            DATA_OUTPUT=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
         *) # preserve positional arguments
            FILENAME=$1
            BASENAME=$(basename "$1")
            PARAMS="$PARAMS data/$BASENAME"
            shift
            ;;
    esac
done

# In case no parameters are given, exit with Help info
if [ -z "$PARAMS" ]; then
  usage
  exit
fi

# In case no filename was given exit and display help and message.
if [ -z "$FILENAME" ]; then
  printf "\nPlease indicate the SAFE container to convert. See Help usage example...\n"
  usage
  exit
fi
# End parser

# Setting up input and output paths
# Get folder of input data
check_path $FILENAME
FILENAME_DIR=$(dirname "${FILENAME}")
echo $FILENAME_DIR
if [ "$is_absolute" = "false" ]; then
  if [ "$FILENAME_DIR" = "." ]; then
    DATA_INPUT=$PWD
  else
    DATA_INPUT=$PWD$FILENAME_DIR
  fi
else
  DATA_INPUT=$FILENAME_DIR
fi

# Check if DATA_OUTPUT was set in the parameters, otherwise default it
if [ -z "$DATA_OUTPUT" ]; then
  DATA_OUTPUT=$DATA_INPUT
fi

# Set DATA_OUTPUT to the desired folder (default or relative/absolute parameter)
check_path $DATA_OUTPUT
if [ "$DATA_INPUT" = "$DATA_OUTPUT" ]; then
    echo input and output folder: $DATA_INPUT
else
    if [ "$is_absolute" = "false" ]; then
      DATA_OUTPUT=$PWD/$DATA_OUTPUT
      echo input folder: $DATA_INPUT
      echo output folder: $DATA_OUTPUT
    else
      echo input folder: $DATA_INPUT
      echo output folder: $DATA_OUTPUT
    fi
fi

check_dir_exists $DATA_OUTPUT
check_resolution $RESOLUTION
# echo params: $PARAMS

# Run sen2cor container and convert data
docker run --rm -v $DATA_INPUT:/sen2cor/data redblanket/sen2cor:v1 $PARAMS

# Data is outputted in the same input folder (folder mounted in docker container).
# This will move it to the desired location indicated with the relative parameter.
if [ "$DATA_INPUT" != "$DATA_OUTPUT" ]; then
    L1C_FILENAME=$BASENAME
    L2A_PREFIX="S2B_MSIL2A_"
    L2A_FILENAME=$L2A_PREFIX${L1C_FILENAME: ${#L2A_PREFIX}:${#L1C_FILENAME}}
    mv $DATA_INPUT/$L2A_FILENAME $DATA_OUTPUT/
fi
