FROM ubuntu:bionic

WORKDIR /tmp/sen2cor

RUN apt-get update && \
    apt-get install -y wget file && \
    wget http://step.esa.int/thirdparties/sen2cor/2.8.0/Sen2Cor-02.08.00-Linux64.run -O ./s2c.run && \
    chmod +x s2c.run && ./s2c.run && rm s2c.run

COPY L2A_GIPP.xml /root/sen2cor/2.8/cfg/L2A_GIPP.xml
COPY l2a_process.sh /usr/local/bin/l2a_process.sh

RUN chmod +x /usr/local/bin/l2a_process.sh

ENTRYPOINT ["/usr/local/bin/l2a_process.sh"]
