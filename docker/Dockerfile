# install phase
FROM centos:7

RUN mkdir -p /gbase && mkdir -p /opt/gbase8s && useradd -m gbasedbt

ADD *.tar prepare.sh /gbase/

ENV JAVA_HOME=/gbase/jre 
ENV PATH=$JAVA_HOME/bin:$PATH

RUN sh /gbase/prepare.sh && \
	sh /gbase/ids_install -i silent -DLICENSE_ACCEPTED=TRUE -DUSER_INSTALL_DIR=/opt/gbase8s && \
	sh /gbase/installclientsdk -i silent -DLICENSE_ACCEPTED=TRUE -DUSER_INSTALL_DIR=/opt/gbase8s

# final phase
FROM centos:7

RUN yum install -y libaio-devel && useradd -m gbasedbt

COPY --from=0 /opt/gbase8s /opt/gbase8s

ADD --chown=gbasedbt:gbasedbt conf/onconfig* conf/sqlhosts* /opt/gbase8s/etc/
ADD entrypoint.sh env.sh /

RUN chown gbasedbt:gbasedbt /opt/gbase8s && \
	mkdir /opt/gbase8s/storage /opt/gbase8s/logs && \
    chown gbasedbt:gbasedbt /opt/gbase8s/storage /opt/gbase8s/logs && \
	echo "ol_generaldata1210 12345/tcp" >> /etc/services && \
	echo "dr_generaldata1210 12346/tcp" >> /etc/services && \
	chmod +x /entrypoint.sh

VOLUME ["/opt/gbase8s/storage", "/opt/gbase8s/logs"]

EXPOSE 12345 12346

ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["/bin/bash"]
