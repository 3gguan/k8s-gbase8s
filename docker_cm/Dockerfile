# install phase
FROM centos:7

RUN mkdir -p /gbase && mkdir -p /opt/gbase8s && useradd -m gbasedbt

ADD *.tar prepare.sh /gbase/

ENV JAVA_HOME=/gbase/jre 
ENV PATH=$JAVA_HOME/bin:$PATH

RUN sh /gbase/prepare.sh && \
	sh /gbase/installclientsdk -i silent -DLICENSE_ACCEPTED=TRUE -DUSER_INSTALL_DIR=/opt/gbase8s

# final phase
FROM centos:7

RUN yum install -y libaio-devel python-setuptools iproute bind-utils && useradd -m gbasedbt && mkdir -p /etc/gbasedbt

COPY --from=0 /opt/gbase8s /opt/gbase8s

ADD --chown=gbasedbt:gbasedbt conf/* /opt/gbase8s/etc/
ADD entrypoint.sh env.sh start_manual.sh check.conf /

RUN chown gbasedbt:gbasedbt /opt/gbase8s && \
	mkdir /opt/gbase8s/logs && \
    chown gbasedbt:gbasedbt /opt/gbase8s/logs && \
	chmod +x /entrypoint.sh

VOLUME ["/opt/gbase8s/logs"]

#EXPOSE 9088 19088 8000

ENTRYPOINT ["sh", "/entrypoint.sh"]
#ENTRYPOINT ["/bin/bash"]
