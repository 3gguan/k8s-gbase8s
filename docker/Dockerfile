# install phase
FROM centos:7.9.2009

RUN mkdir -p /gbase && \
    mkdir -p /opt/gbase8s && \
    useradd -m -u 1000 gbasedbt && \
    echo "gbasedbt:gbasedbt" | chpasswd

ADD *.tar prepare.sh /gbase/

RUN sh /gbase/prepare.sh && \
    sh /gbase/ids_install -i silent -DLICENSE_ACCEPTED=TRUE -DUSER_INSTALL_DIR=/opt/gbase8s && \
    sh /gbase/installclientsdk -i silent -DLICENSE_ACCEPTED=TRUE -DUSER_INSTALL_DIR=/opt/gbase8s

# build server phase
FROM golang

COPY server /server
ENV GOPROXY https://goproxy.cn
RUN cd /server && go build -o apiserver main.go

# final phase
FROM centos:7.9.2009

RUN useradd -m -u 1000 gbasedbt && \
    echo "gbasedbt:gbasedbt" | chpasswd && \
    mkdir -p /etc/gbasedbt

COPY --from=0 /opt/gbase8s /opt/gbase8s
COPY --from=1 /server/apiserver /opt/server/

COPY --chown=gbasedbt:gbasedbt conf/single/onconfig* conf/single/sqlhosts* /opt/gbase8s/etc/
COPY conf/single/allowed.surrogates /etc/gbasedbt/
COPY scripts /scripts

RUN chown gbasedbt:gbasedbt /opt/gbase8s && \
    mkdir /opt/gbase8s/storage /opt/gbase8s/logs /opt/gbase8s/tape && \
    chown gbasedbt:gbasedbt /opt/gbase8s/storage /opt/gbase8s/logs && \
    chmod +x /scripts/*.sh && \
    touch /opt/gbase8s/etc/hostfile /opt/gbase8s/etc/hostuser && \
    chmod 660 /opt/gbase8s/etc/hostfile /opt/gbase8s/etc/hostuser && \
    chown gbasedbt.gbasedbt /opt/gbase8s/etc/hostfile /opt/gbase8s/etc/hostuser && \
    echo ". /scripts/env.sh" >> /etc/bashrc

VOLUME ["/opt/gbase8s/storage", "/opt/gbase8s/logs", "/opt/gbase8s/tape"]

EXPOSE 9088 19088 8080

ENTRYPOINT ["sh", "/scripts/entrypoint.sh"]
#ENTRYPOINT ["/bin/bash"]
