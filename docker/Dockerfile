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

RUN yum install -y libaio-devel python-setuptools && useradd -m gbasedbt && mkdir -p /etc/gbasedbt

COPY --from=0 /opt/gbase8s /opt/gbase8s

ADD --chown=gbasedbt:gbasedbt conf/single/onconfig* conf/single/sqlhosts* /opt/gbase8s/etc/
ADD conf/single/allowed.surrogates /etc/gbasedbt/
ADD entrypoint.sh env.sh /
ADD Django-1.11.29.tar.gz /
ADD server/ /server/

RUN chown gbasedbt:gbasedbt /opt/gbase8s && \
	mkdir /opt/gbase8s/storage /opt/gbase8s/logs /opt/gbase8s/tape && \
    chown gbasedbt:gbasedbt /opt/gbase8s/storage /opt/gbase8s/logs && \
	chmod +x /entrypoint.sh && \
	touch /opt/gbase8s/etc/hostfile /opt/gbase8s/etc/hostuser && \
	chmod 660 /opt/gbase8s/etc/hostfile /opt/gbase8s/etc/hostuser && \
	chown gbasedbt.gbasedbt /opt/gbase8s/etc/hostfile /opt/gbase8s/etc/hostuser && \
	cd /Django-1.11.29 && python setup.py install

VOLUME ["/opt/gbase8s/storage", "/opt/gbase8s/logs", "/opt/gbase8s/tape"]

#EXPOSE 9088 19088 8000

ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["/bin/bash"]
