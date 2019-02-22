# sen2cor-docker
Docker container and command script for Sen2Cor 2.5.5 (March 2018)

## Introduction

The docker container is built on top of `ubuntu:bionic` and is based on the Linux64 installer available from ESA [here](http://step.esa.int/main/third-party-plugins-2/sen2cor/).

A configuration file is loaded from the repository. This version includes the configuration of the `dem` folder.
At run time the `/root/sen2cor/2.5/dem` folder can be mounted on a shared drive/s3bucket in order to be shared among the nodes in the cluster.
An `aux_data` folder containing the CCI data (the folder should also contain the original `GlobalSnowMap.tiff` and `__init__.py` files) can also be mounted to `/sen2cor/Sen2Cor-02.05.05-Linux64/lib/python2.7/site-packages/sen2cor/aux_data` in order to use CCI data.

### Docker Image
The container image can be found [here](https://cloud.docker.com/u/redblanket/repository/docker/redblanket/sen2cor).
```
docker pull redblanket/sen2cor:latest
```

#### Inner container info

```
SEN2COR_HOME=/root/sen2cor/2.5
SEN2COR_BIN=/sen2cor/Sen2Cor-02.05.05-Linux64/lib/python2.7/site-packages/sen2cor
```

## Installation
In order to use sen2cor it is sufficient to copy and run `sen2cor.sh`. It will pull the image from the repository and display available commands.

For a better experience add it to the PATH using the `install.sh` script in the repo or this snippet:
```
git clone https://github.com/dzanaga/sen2cor-docker.git
cd sen2cor-docker
chmod +x sen2cor.sh
cp sen2cor.sh ~/.local/bin/sen2cor
```

## Usage Example
To apply sen2cor atmospheric correction, download and unzip a Sentinel 2 product,
and invoke the script:
```
sen2cor /path/to/S2B_MSIL1C_METADATA.SAFE
```
This will apply the correction for all resolutions `(10, 20, 60)` and save the data in the same position.

It is also possible to specify a destination folder and the desired resolution:
```
sen2cor --resolution 60 --output-folder /path/to/destination/folder/ /path/to/S2B_MSIL1C_METADATA.SAFE
```
