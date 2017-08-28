# gluster-ubuntu-minimal Docker image

GlusterFS on Ubuntu Slim w/o systemd

**This image is entirely experimental. The tags are just varying degrees of hacks.**

## Tags

* `latest` ([Dockerfile](https://github.com/jarrpa/gluster-containers/tree/ubuntu-minimal/Ubuntu-minimal)):
  Latest stable image

## Description

The gluster-ubuntu-minimal image is an image running GlusterFS on Ubuntu Slim. It focuses on running GlusterFS without systemd, assuming an external container orchestrator will take care of restarting the entire container should any of the critical processes fail. Since systemd expect to be PID 1, removing it allows the container to be used in environments where multiple containers share the same PID namespace and PID 1 cannot be guaranteed.
