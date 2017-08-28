FROM fedora

ENV NAME="gluster-fedora-minimal" \
    DESC="GlusterFS on Fedora w/o systemd" \
    VERSION=0 \
    RELEASE=1 \
    ARCH=x86_64 \
    REPO="$FGC"

LABEL name="$REPO/$NAME" \
      version="$VERSION" \
      release="$RELEASE.$DISTTAG" \
      architecture="$ARCH" \
      vendor="Red Hat, Inc" \
      summary="$DESC" \
      usage="docker run -d $REPO/$NAME" \
      io.k8s.display-name="$DESC" \
      io.k8s.description="GlusterFS is a distributed and scalable network filesystem. Using common, off-the-shelf hardware you can create large, distributed storage solutions for media streaming, data analysis, and other data- and bandwidth-intensive tasks." \
      io.openshift.tags="gluster,glusterfs,gluster-fedora" \
      com.redhat.component="$NAME" \
      maintainer="Jose A. Rivera <jarrpa@redhat.com>"

COPY gluster-setup.sh systemctl-mock.sh /

RUN dnf --setopt=tsflags=nodocs -y upgrade && \
    dnf --setopt=tsflags=nodocs -y install glusterfs glusterfs-server glusterfs-geo-replication procps-ng xfsprogs && \
    dnf clean all && \
    mkdir -p /etc/glusterfs_bkp /var/lib/glusterd_bkp /var/log/glusterfs_bkp && \
    cp -r /etc/glusterfs/* /etc/glusterfs_bkp && \
    cp -r /var/lib/glusterd/* /var/lib/glusterd_bkp && \
    sed -i.save -e "s#udev_sync = 1#udev_sync = 0#" -e "s#udev_rules = 1#udev_rules = 0#" -e "s#use_lvmetad = 1#use_lvmetad = 0#" /etc/lvm/lvm.conf && \
    mv /gluster-setup.sh /usr/sbin/gluster-setup.sh && mv /systemctl-mock.sh /bin/systemctl && \
    chmod 500 /usr/sbin/gluster-setup.sh && chmod 655 /bin/systemctl

VOLUME [ "/sys/fs/cgroup" ]

EXPOSE 111 24007 49152 49153 49154 49156 49157 49158 49159 49160 49161 49162 49163

CMD ["/usr/sbin/gluster-setup.sh"]

