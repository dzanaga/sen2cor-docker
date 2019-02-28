#!/usr/bin/env bash

# inner container sen2cor cfg settings folder
SEN2COR_HOME="/root/sen2cor/2.5"

# output folder that will be mounted on the shared drive/S3 bucket
OUTPUT="/tmp/output"

# temp output folder hidden from the host (when processing on a cluster, this
# folder will be on node memory, and only later the output will be moved on the
# cluster shared drive/S3 bucket mounted on OUTPUT)
OUTPUT_TMP="/tmp/output_tmp"

# Run sen2cor
/tmp/sen2cor/Sen2Cor-02.05.05-Linux64/bin/L2A_Process "$@"

# if host user id is given to container, create that user and change permissions of files
if [ ! -z "$HOSTUSER_ID" ]; then
  # create host user inside container
  groupadd -g $HOSTUSER_ID user
  useradd --shell /bin/bash -u $HOSTUSER_ID -g $HOSTUSER_ID -o -c "" -m user

  chown -R user:user "$OUTPUT_TMP"

  chown -R user:user "$SEN2COR_HOME/dem"
  chown -R user:user "$SEN2COR_HOME/log"
fi

# move files to mounted output folder
mv ${OUTPUT_TMP}/* ${OUTPUT}
