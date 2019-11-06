FROM rawmind/alpine-base:3.10-1
MAINTAINER Raul Sanchez <rawmind@gmail.com>

ARG SERVICE_NAME=hello-world-app
ARG SERVICE_HOME=/opt/hello-world-app
ARG SERVICE_REPO=rawmind0
ARG SERVICE_VERSION=dev

#Set environment
ENV SERVICE_NAME=${SERVICE_NAME} \
    SERVICE_HOME=${SERVICE_HOME} \
    SERVICE_USER=rancher \
    SERVICE_UID=10012 \
    SERVICE_GROUP=rancher \
    SERVICE_GID=10012 \
    VERSION=${SERVICE_VERSION} \
    GOMAXPROCS=2 \
    GOROOT=/usr/lib/go \
    GOPATH=/opt/src \
    GOBIN=/gopath/bin
ENV PATH=${PATH}:${SERVICE_HOME}

# Add files
ADD . /opt/src/src/github.com/rawmind0/hello-world-app/
RUN apk add --no-cache git mercurial bzr make go musl-dev && \
    cd /opt/src/src/github.com/rawmind0/hello-world-app && \
    make test && \
    make build && \
    mkdir ${SERVICE_HOME} && \
    cp -Rp ${SERVICE_NAME} img/* ${SERVICE_HOME}/ && \
    cd ${SERVICE_HOME} && \ 
    rm -rf /opt/src /gopath && \
    apk del --no-cache git mercurial bzr make go musl-dev && \
    addgroup -g ${SERVICE_GID} ${SERVICE_GROUP} && \
    adduser -g "${SERVICE_NAME} user" -D -h ${SERVICE_HOME} -G ${SERVICE_GROUP} -s /sbin/nologin -u ${SERVICE_UID} ${SERVICE_USER} && \
    chown -R ${SERVICE_USER}:${SERVICE_GROUP} ${SERVICE_HOME} && \
    setcap 'cap_net_bind_service=+ep' ${SERVICE_HOME}/${SERVICE_NAME}
USER $SERVICE_USER
WORKDIR $SERVICE_HOME
ENTRYPOINT ["/opt/hello-world-app/hello-world-app"]