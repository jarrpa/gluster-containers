# gluster-fedora-minimal Docker image

GlusterFS on Fedora w/o systemd

**This image is entirely experimental. The tags are just varying degrees of hacks.**

## Tags

* `latest` ([Dockerfile](https://github.com/jarrpa/gluster-containers/tree/fedora-minimal/Fedora-minimal)):
  Latest stable image
* `block` ([Dockerfile](https://github.com/jarrpa/gluster-containers/tree/fedora-minimal-block/Fedora-minimal)):
  WIP image to enable glusterblock using [unofficial sources](https://copr.fedorainfracloud.org/coprs/jarrpa/gluster-block/)
* `dev` ([Dockerfile](https://github.com/jarrpa/gluster-containers/tree/fedora-minimal-dev/Fedora-minimal)):
  Latest WIP image, high potential for nonsense

## Description

The gluster-fedora-minimal image is an image running GlusterFS on Fedora. It focuses on running GlusterFS without systemd, assuming an external container orchestrator will take care of restarting the entire container should any of the critical processes fail. Since systemd expect to be PID 1, removing it allows the container to be used in environments where multiple containers share the same PID namespace and PID 1 cannot be guaranteed.
