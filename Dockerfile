# syntax = docker/dockerfile:1.4
# vim: syntax=dockerfile
FROM fedora:41 AS build


ARG CEPH_CLUSTER_VERSION="main"
ARG CEPH_CLUSTER_CEPH_REPO_BASEURL


ARG MICRODNF_OPTS="\
    --nobest \
    --nodocs \
    --setopt=install_weak_deps=0 \
    --setopt=keepcache=1 \
    --setopt=cachedir=/var/cache/dnf \
  "

ARG CEPH_PACKAGES="\
    ceph-common \
    ceph-mon \
    ceph-osd \
    ceph-mds \
    ceph-mgr \
    ceph-mgr-dashboard \
    ceph-radosgw \
    ceph-exporter \
    hostname \
    net-tools \
    iproute \
    "
# TODO: To remove when ceph-mgr-dashboard defines these as deps
ARG EXTRA_PACKAGES="\
    python3-grpcio \
    python3-grpcio-tools \
    jq \
    "
ARG DEBUG_PACKAGES="\
    procps-ng \
    strace \
    perf \
    ltrace \
    lsof \
    "


COPY <<EOF /etc/yum.repos.d/ceph.repo
[Ceph]
name=Ceph packages for fedora
baseurl=http://apt-mirror.front.sepia.ceph.com/lab-extras/9
enabled=1
priority=2
gpgcheck=0

EOF

# Copy set-repo.sh into image
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y $MICRODNF_OPTS \
        $CEPH_PACKAGES \
        $EXTRA_PACKAGES


#------------------------------------------------------------------------------
FROM build

LABEL maintainer \
      ceph=True \
      RELEASE \
      GIT_REPO \
      GIT_BRANCH \
      GIT_COMMIT

ENV MON=1 \
    MGR=1 \
    OSD=3 \
    MDS=0 \
    FS=0 \
    RGW=0 \
    NFS=0 \
    CEPH_PORT=10000 \
    CEPH_VSTART_ARGS="--memstore"

ENV CEPH_BIN=/usr/bin \
    CEPH_LIB=/usr/lib64/ceph \
    CEPH_CONF_PATH=/etc/ceph \
    EC_PATH=/usr/lib64/ceph/erasure-code \
    OBJCLASS_PATH=/usr/lib64/rados-classes \
    MGR_PYTHON_PATH=/usr/share/ceph/mgr \
    PYBIND=/usr/share/ceph/mgr

VOLUME $CEPH_CONF_PATH
RUN chown ceph:ceph $CEPH_CONF_PATH

RUN ln -sf $EC_PATH/* $CEPH_LIB && \
    ln -sf $OBJCLASS_PATH/* $CEPH_LIB && \
    ln -sf $CEPH_LIB/compressor/* $CEPH_LIB

USER ceph
WORKDIR /ceph
ADD --chown=ceph:ceph --chmod=755 \
    https://raw.githubusercontent.com/ceph/ceph/${CEPH_CLUSTER_VERSION:?}/src/vstart.sh .

COPY <<EOF ./CMakeCache.txt
ceph_SOURCE_DIR:STATIC=/ceph
WITH_MGR_DASHBOARD_FRONTEND:BOOL=ON
WITH_RBD:BOOL=ON
EOF

ENTRYPOINT \
    ./vstart.sh --new $CEPH_VSTART_ARGS && \
    sleep infinity

