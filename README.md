# sen2cor-docker
Docker container and command script for Sen2Cor 2.5.5 (March 2018)

## Introduction

The docker container is built on top of `ubuntu:bionic` and is based on the Linux64 installer available from ESA [here](http://step.esa.int/main/third-party-plugins-2/sen2cor/).

### Dockerfile
```
FROM ubuntu:bionic
WORKDIR /sen2cor
RUN apt-get update && \
    apt-get install -y wget file && \
    wget http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run -O ./s2c.run && \
    chmod +x s2c.run && ./s2c.run && rm s2c.run && mkdir data
ENTRYPOINT ["/sen2cor/Sen2Cor-02.05.05-Linux64/bin/L2A_Process"]
CMD []
```

### Docker Image
The container image was pushed to docker hub and can be found [here](https://cloud.docker.com/u/redblanket/repository/docker/redblanket/sen2cor).
```docker pull redblanket/sen2cor:v1```

## Installation
In order to use sen2cor is sufficient to copy the sen2cor.sh script and run it. It will pull the image from the repository and display available commands.

It's also possible to use the `install.sh` script in the repo:
```
git clone https://github.com/dzanaga/sen2cor-docker.git
chmod +x sen2cor.sh
cp sen2cor.sh ~/.local/bin/sen2cor
```

## Usage Example
To apply sen2cor atmospheric correction, download and unzip a Sentinel 2 product,
and invoke the script:
```
sen2cor /path/to/S2B_MSIL1C_METADATA.SAFE
```
This will apply the correction for all resolutions (10, 20, 60) and save the data in the same position.

It is also possible to specify a destination folder and the desired resolution:
```
sen2cor --resolution 60 --output-folder /path/to/destination/folder/ /path/to/S2B_MSIL1C_METADATA.SAFE
```
