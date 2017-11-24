FROM debian:stable-slim

ENV NAME="gluster-debian-minimal" \
    DESC="GlusterFS on Debian w/o systemd" \
    VERSION="3.12" \
    RELEASE="1" \
    ARCH="x86_64" \
    REPO="jarrpa" \
    TINI_VERSION="v0.16.1"

LABEL name="$REPO/$NAME" \
      version="$VERSION" \
      release="$RELEASE" \
      architecture="$ARCH" \
      summary="$DESC" \
      usage="docker run -d $REPO/$NAME" \
      io.k8s.display-name="$DESC" \
      io.k8s.description="GlusterFS is a distributed and scalable network filesystem. Using common, off-the-shelf hardware you can create large, distributed storage solutions for media streaming, data analysis, and other data- and bandwidth-intensive tasks." \
      io.openshift.tags="gluster,glusterfs,gluster-debian" \
      maintainer="Jose A. Rivera <jarrpa@redhat.com>"

# Grab tini, a tiny init replacement for containers.
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini \
    https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc \
    /

RUN apt-get -yq --no-install-recommends update && \
    # Install prereqs for getting and verifying GlusterFS
    apt-get -yq --no-install-recommends install wget gnupg2 dirmngr apt-transport-https ca-certificates && \
    wget -q -O - http://download.gluster.org/pub/gluster/glusterfs/${VERSION}/rsa.pub | apt-key add - 2>/dev/null && \
    DEBID=$(grep 'VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"') && \
    DEBVER=$(grep 'VERSION=' /etc/os-release | grep -Eo '[a-z]+') && \
    echo deb https://download.gluster.org/pub/gluster/glusterfs/${VERSION}/LATEST/Debian/${DEBID}/apt ${DEBVER} main > /etc/apt/sources.list.d/gluster.list && \
    apt-get -yq --no-install-recommends update && \
    apt-get -yq --no-install-recommends install glusterfs-server rpcbind lvm2 thin-provisioning-tools procps xfsprogs && \
    apt-get -yq autoremove && apt-get -yq clean && \
    # Verify tini
    gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 && \
    gpg --verify /tini.asc && \
    # Trim image contents down further, saves ~18MB.
    tar -rf usr/share/copyrights.tar usr/share/doc/*/copyright && gzip /usr/share/copyrights.tar && \
    rm -rf \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/info \
        /usr/share/locale \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/* \
        /var/log/* \
        /var/cache/debconf/* \
        /usr/share/common-licenses* \
        ~/.bashrc \
        /etc/systemd \
        /lib/lsb \
        /lib/udev \
        /usr/lib/x86_64-linux-gnu/gconv/IBM* \
        /usr/lib/x86_64-linux-gnu/gconv/EBC* && \
    mkdir -p /usr/share/man/man1 /usr/share/man/man2 \
        /usr/share/man/man3 /usr/share/man/man4 \
        /usr/share/man/man5 /usr/share/man/man6 \
        /usr/share/man/man7 /usr/share/man/man8 && \
    # Back up the default/base configuration. The target directories get
    # overwritten with the directories from the host which are initially
    # empty.
    mkdir -p /etc/glusterfs_bkp /var/lib/glusterd_bkp && \
    cp -r /etc/glusterfs/* /etc/glusterfs_bkp && \
    cp -r /var/lib/glusterd/* /var/lib/glusterd_bkp && \
    # Disable udev and metadata caching (which requires udev) for LVM.
    sed -i.save -e "s#udev_sync = 1#udev_sync = 0#" -e "s#udev_rules = 1#udev_rules = 0#" -e "s#use_lvmetad = 1#use_lvmetad = 0#" /etc/lvm/lvm.conf && \
    chmod 700 /tini

COPY systemctl-mock.sh gluster-setup.sh /
RUN mv /gluster-setup.sh /usr/sbin/gluster-setup.sh && \
    # heketi expects systemctl to be present, so fake it.
    mv /systemctl-mock.sh /bin/systemctl && \
    chmod 655 /bin/systemctl && chmod 500 /usr/sbin/gluster-setup.sh

EXPOSE 111 24007 49152 49153 49154 49156 49157 49158 49159 49160 49161 49162 49163

CMD [ "/tini", "-sg", "--", "/usr/sbin/gluster-setup.sh" ]

