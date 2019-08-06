FROM ubuntu:18.04

ENV CATTLE_HELM_VERSION v2.10.0-rancher10

ENV ARCH amd64
RUN apt-get update && \
    apt-get install -y gcc ca-certificates git wget curl vim less file xz-utils unzip && \
    rm -f /bin/sh && ln -s /bin/bash /bin/sh
RUN curl -sLf https://github.com/rancher/machine-package/releases/download/v0.15.0-rancher5-3/docker-machine-${ARCH}.tar.gz | tar xvzf - -C /usr/bin

ENV GOLANG_ARCH_amd64=amd64 GOLANG_ARCH_arm=armv6l GOLANG_ARCH_arm64=arm64 GOLANG_ARCH=GOLANG_ARCH_${ARCH} \
    GOPATH=/go PATH=/go/bin:/usr/local/go/bin:${PATH} SHELL=/bin/bash

RUN curl -sLf https://storage.googleapis.com/golang/go1.11.linux-${!GOLANG_ARCH}.tar.gz | tar -xzf - -C /usr/local && \
    go get github.com/rancher/trash && \
    curl -L https://raw.githubusercontent.com/alecthomas/gometalinter/v3.0.0/scripts/install.sh | sh && \
    go get -d golang.org/x/tools/cmd/goimports && \
    # This needs to be kept up to date with rancher/types
    git -C /go/src/golang.org/x/tools/cmd/goimports checkout -b release-branch.go1.12 origin/release-branch.go1.12 && \
    go install golang.org/x/tools/cmd/goimports

ENV HELM_URL_amd64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/helm \
    HELM_URL_arm64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/helm-arm64 \
    HELM_URL=HELM_URL_${ARCH} \
    TILLER_URL_amd64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/tiller \
    TILLER_URL_arm64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/tiller-arm64 \
    TILLER_URL=TILLER_URL_${ARCH}

RUN curl -sLf ${!HELM_URL} > /usr/bin/helm && \
    curl -sLf ${!TILLER_URL} > /usr/bin/tiller && \
    chmod +x /usr/bin/helm /usr/bin/tiller && \
    helm init -c && \
    helm plugin install https://github.com/rancher/helm-unittest

ENV RKE_URL_amd64=https://github.com/rancher/rke/releases/download/v0.2.0-rc8/rke_linux-amd64 \
    RKE_URL_arm64=https://github.com/rancher/rke/releases/download/v0.2.0-rc8/rke_linux-arm64 \
    RKE_URL=RKE_URL_${ARCH}

RUN curl -sLf ${!RKE_URL} > /usr/bin/rke && chmod +x /usr/bin/rke

RUN apt-get update && \
    apt-get install -y tox python3.7 python3-dev python3.7-dev libffi-dev libssl-dev

ENV HELM_HOME /root/.helm
WORKDIR /go/src/github.com/rancher/rancher/
COPY ./ /go/src/github.com/rancher/rancher/
RUN sh -c ./scripts/build && mv bin/rancher /usr/bin/rancher

RUN apt-get update && apt-get install -y git curl ca-certificates unzip xz-utils && \
    useradd rancher && \
    mkdir -p /var/lib/rancher/etcd /var/lib/cattle /opt/jail /opt/drivers/management-state/bin && \
    chown -R rancher /var/lib/rancher /var/lib/cattle /usr/local/bin
RUN mkdir /root/.kube && \
    ln -s /usr/bin/rancher /usr/bin/kubectl && \
    ln -s /var/lib/rancher/management-state/cred/kubeconfig.yaml /root/.kube/config && \
    ln -s /usr/bin/rancher /usr/bin/reset-password && \
    ln -s /usr/bin/rancher /usr/bin/ensure-default-admin && \
    rm -f /bin/sh && ln -s /bin/bash /bin/sh
WORKDIR /var/lib/rancher

ARG ARCH=amd64
ARG SYSTEM_CHART_DEFAULT_BRANCH=release-v2.2

ENV CATTLE_SYSTEM_CHART_DEFAULT_BRANCH=$SYSTEM_CHART_DEFAULT_BRANCH
ENV CATTLE_HELM_VERSION v2.10.0-rancher11
ENV CATTLE_MACHINE_VERSION v0.15.0-rancher8-1
ENV LOGLEVEL_VERSION v0.1.2
ENV TINI_VERSION v0.18.0
ENV TELEMETRY_VERSION v0.5.6


RUN curl -sLf https://github.com/rancher/machine-package/releases/download/${CATTLE_MACHINE_VERSION}/docker-machine-${ARCH}.tar.gz | tar xvzf - -C /usr/bin && \
    curl -sLf https://github.com/rancher/loglevel/releases/download/${LOGLEVEL_VERSION}/loglevel-${ARCH}-${LOGLEVEL_VERSION}.tar.gz | tar xvzf - -C /usr/bin

ENV TINI_URL_amd64=https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini \
    TINI_URL_arm64=https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-arm64 \
    TINI_URL=TINI_URL_${ARCH}

ENV HELM_URL_amd64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/helm \
    HELM_URL_arm64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/helm-arm64 \
    HELM_URL=HELM_URL_${ARCH} \
    TILLER_URL_amd64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/tiller \
    TILLER_URL_arm64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/tiller-arm64 \
    TILLER_URL=TILLER_URL_${ARCH}

RUN curl -sLf ${!TINI_URL} > /usr/bin/tini && \
    curl -sLf ${!HELM_URL} > /usr/bin/helm && \
    curl -sLf ${!TILLER_URL} > /usr/bin/tiller && \
    curl -sLf https://github.com/rancher/telemetry/releases/download/${TELEMETRY_VERSION}/telemetry-${ARCH} > /usr/bin/telemetry && \
    chmod +x /usr/bin/helm /usr/bin/tini /usr/bin/telemetry /usr/bin/tiller

ENV CATTLE_UI_PATH /usr/share/rancher/ui
ENV CATTLE_UI_VERSION 2.2.90
ENV CATTLE_CLI_VERSION v2.2.0

# Please update the api-ui-version in pkg/settings/settings.go when updating the version here.
ENV CATTLE_API_UI_VERSION 1.1.6

RUN mkdir -p /var/log/auditlog
ENV AUDIT_LOG_PATH /var/log/auditlog/rancher-api-audit.log
ENV AUDIT_LOG_MAXAGE 10
ENV AUDIT_LOG_MAXBACKUP 10
ENV AUDIT_LOG_MAXSIZE 100
ENV AUDIT_LEVEL 0
VOLUME /var/log/auditlog

RUN mkdir -p /usr/share/rancher/ui && \
    cd /usr/share/rancher/ui && \
    curl -sL https://releases.rancher.com/ui/${CATTLE_UI_VERSION}.tar.gz | tar xvzf - --strip-components=1 && \
    mkdir -p /usr/share/rancher/ui/api-ui && \
    cd /usr/share/rancher/ui/api-ui && \
    curl -sL https://releases.rancher.com/api-ui/${CATTLE_API_UI_VERSION}.tar.gz | tar xvzf - --strip-components=1 && \
    cd /var/lib/rancher

ENV CATTLE_CLI_URL_DARWIN  https://releases.rancher.com/cli2/${CATTLE_CLI_VERSION}/rancher-darwin-amd64-${CATTLE_CLI_VERSION}.tar.gz
ENV CATTLE_CLI_URL_LINUX   https://releases.rancher.com/cli2/${CATTLE_CLI_VERSION}/rancher-linux-amd64-${CATTLE_CLI_VERSION}.tar.gz
ENV CATTLE_CLI_URL_WINDOWS https://releases.rancher.com/cli2/${CATTLE_CLI_VERSION}/rancher-windows-386-${CATTLE_CLI_VERSION}.zip

ARG VERSION=dev
ENV CATTLE_SERVER_VERSION ${VERSION}
COPY ./package/entrypoint.sh  /usr/bin/
COPY ./package/jailer.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENV CATTLE_AGENT_IMAGE rancher/rancher-agent:${VERSION}
ENV CATTLE_WINDOWS_AGENT_IMAGE rancher/rancher-agent:${VERSION}-nanoserver-1803
ENV CATTLE_SERVER_IMAGE rancher/rancher
ENV ETCD_UNSUPPORTED_ARCH=${ARCH}

ENV SSL_CERT_DIR /etc/rancher/ssl
VOLUME /var/lib/rancher

ENTRYPOINT ["entrypoint.sh"]