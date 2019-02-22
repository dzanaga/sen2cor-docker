FROM ubuntu:bionic
WORKDIR /sen2cor
RUN apt-get update && \
    apt-get install -y wget file s3fs && \
    wget http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run -O ./s2c.run && \
    chmod +x s2c.run && ./s2c.run && rm s2c.run

COPY L2A_GIPP.xml /root/sen2cor/2.5/cfg/L2A_GIPP.xml

ENTRYPOINT ["/sen2cor/Sen2Cor-02.05.05-Linux64/bin/L2A_Process"]
CMD []
