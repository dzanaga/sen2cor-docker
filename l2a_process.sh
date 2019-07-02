#!/usr/bin/env bash

# inner container sen2cor cfg settings folder
SEN2COR_HOME="/root/sen2cor/2.8"
SEN2COR_PROCBIN="/tmp/sen2cor/Sen2Cor-02.08.00-Linux64/bin"
# output folder that will be mounted on the shared drive/S3 bucket
OUTPUT="/tmp/output"

# temp output folder hidden from the host (when processing on a cluster, this
# folder will be on node memory, and only later the output will be moved on the
# cluster shared drive/S3 bucket mounted on OUTPUT)
OUTPUT_TMP="/tmp/output_tmp"

# Run sen2cor (timeout of 4500 seconds prevent sen2cor to stay in error loop)
timeout 4500 ${SEN2COR_PROCBIN}/L2A_Process --output_dir ${OUTPUT_TMP} "$@"

# if host user id is given to container, create that user and change permissions of files
if [ ! -z "$HOSTUSER_ID" ]; then

  # in case group id is not specified, use user id
  if [ -z "$HOSTGROUP_ID" ]; then
    HOSTGROUP_ID=$HOSTUSER_ID
  fi

  # create host user inside container
  groupadd -g $HOSTGROUP_ID hostgroup
  useradd --shell /bin/bash -u $HOSTUSER_ID -g $HOSTGROUP_ID -o -c "" -m user

  chown -R user:hostgroup "$OUTPUT_TMP"

  chown -R user:hostgroup "$SEN2COR_HOME/dem"
  chown -R user:hostgroup "$SEN2COR_HOME/log"
fi

# move files to mounted output folder
mv ${OUTPUT_TMP}/* ${OUTPUT}
