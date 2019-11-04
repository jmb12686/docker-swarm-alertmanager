## Build stage - Build prometheus alertmanager from latest source
FROM golang:alpine as builder

RUN apk update && apk add --no-cache git && \
    apk add --no-cache make && \
    apk add --no-cache gcc && \
    apk add --no-cache curl && \
    apk add --no-cache libc-dev && \
    apk add --no-cache bash

# RUN GO15VENDOREXPERIMENT=1 go get github.com/prometheus/alertmanager/cmd/...
# WORKDIR $GOPATH/src/github.com/prometheus/alertmanager/
# RUN make build

RUN mkdir -p $GOPATH/src/github.com/prometheus
WORKDIR $GOPATH/src/github.com/prometheus
RUN git clone  -b 'v0.19.0' --single-branch --depth 1 https://github.com/prometheus/alertmanager.git
WORKDIR $GOPATH/src/github.com/prometheus/alertmanager/
RUN make build


## Run stage - Install dependencies (if any) and copy artifacts from builder stage
FROM alpine 

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="John Belisle" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="alertmanager-swarm" \
  org.label-schema.description="Prometheus Alertmanager with added support for High Availability in Docker Swarm" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/jmb12686/docker-swarm-alertmanager" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/jmb12686/docker-swarm-alertmanager" \
  org.label-schema.vendor="jmb12686" \
  org.label-schema.schema-version="1.0"



COPY --from=builder go/src/github.com/prometheus/alertmanager/alertmanager /bin/alertmanager
COPY --from=builder go/src/github.com/prometheus/alertmanager/amtool /bin/amtool
COPY conf/alertmanager.yml /etc/alertmanager/alertmanager.yml
COPY conf/docker-entrypoint.sh /etc/alertmanager/docker-entrypoint.sh

RUN mkdir -p /alertmanager && \
    chown -R nobody:nogroup /etc/alertmanager /alertmanager

USER        nobody
EXPOSE      9093
VOLUME      [ "/alertmanager" ]


RUN ["chmod", "+x", "/etc/alertmanager/docker-entrypoint.sh"]
RUN ["dos2unix", "/etc/alertmanager/docker-entrypoint.sh"]
WORKDIR     /alertmanager
ENTRYPOINT  [ "/etc/alertmanager/docker-entrypoint.sh"]
CMD         [ "/bin/alertmanager", "--config.file=/etc/alertmanager/alertmanager.yml", \
            "--storage.path=/alertmanager" ]