#!/bin/bash

###
# Description: Script to move the glusterfs initial setup to bind mounted directories of Atomic Host.
# Copyright (c) 2016 Red Hat, Inc. <http://www.redhat.com>
#
# This file is part of GlusterFS.
#
# This file is licensed to you under your choice of the GNU Lesser
# General Public License, version 3 or any later version (LGPLv3 or
# later), or the GNU General Public License, version 2 (GPLv2), in all
# cases as published by the Free Software Foundation.
###

PROCS=""

GLUSTERFS_CONF_DIR="/etc/glusterfs"
GLUSTERFS_LOG_DIR="/var/log/glusterfs"
GLUSTERFS_META_DIR="/var/lib/glusterd"
GLUSTERFS_LOG_CONT_DIR="${GLUSTERFS_LOG_DIR}/container"
GLUSTERFS_CUSTOM_FSTAB="/var/lib/heketi/fstab"

: "${GLUSTER_BRICKMULTIPLEX:=yes}"
: "${GLUSTERFS_LOG_LEVEL:=INFO}"

mkdir -p $GLUSTERFS_LOG_CONT_DIR

start_setup() {
  for i in $GLUSTERFS_CONF_DIR $GLUSTERFS_META_DIR
  do
    if ! test "$(ls $i)"
    then
          bkp=$i"_bkp"
          cp -r $bkp/* $i
          if [ $? -eq 1 ]
          then
                echo "Failed to copy $i"
                exit 1
          fi
          ls -R $i > ${GLUSTERFS_LOG_CONT_DIR}/${i//\//_}_ls
    fi
  done

  if [ -s "$GLUSTERFS_CUSTOM_FSTAB" ]; then
        touch $GLUSTERFS_LOG_CONT_DIR/brickattr
        touch $GLUSTERFS_LOG_CONT_DIR/failed_bricks

        sleep 5

        pvscan | tee $GLUSTERFS_LOG_CONT_DIR/pvscan
        vgscan | tee $GLUSTERFS_LOG_CONT_DIR/vgscan
        lvscan | tee $GLUSTERFS_LOG_CONT_DIR/lvscan
        mount -a --fstab $GLUSTERFS_CUSTOM_FSTAB | tee $GLUSTERFS_LOG_CONT_DIR/mountfstab
        if [ $? -eq 1 ]; then
              echo "mount binary not failed" | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
              exit 1
        fi
        echo "Mount command Successful" | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
        sleep 40
        cut -f 2 -d " " $GLUSTERFS_CUSTOM_FSTAB | while read -r line; do
              if grep -qs "$line" /proc/mounts; then
                   echo "$line mounted." | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   if test "ls $line/brick"
                   then
                         echo "$line/brick is present" | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
                         getfattr -d -m . -e hex "$line/brick" | tee -a $GLUSTERFS_LOG_CONT_DIR/brickattr
                   else
                         echo "$line/brick is not present" | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
                         sleep 1
                   fi
              else
                   grep "$line" "$GLUSTERFS_CUSTOM_FSTAB" | tee -a $GLUSTERFS_LOG_CONT_DIR/failed_bricks
                   echo "$line not mounted." | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   sleep 0.5
             fi
        done
        if [ "$(wc -l $GLUSTERFS_LOG_CONT_DIR/failed_bricks | awk '{print $1}')" -gt 1 ]
        then
              vgscan --mknodes | tee $GLUSTERFS_LOG_CONT_DIR/vgscan_mknodes
              sleep 10
              mount -a --fstab $GLUSTERFS_LOG_CONT_DIR/failed_bricks
        fi
  fi
}

startup() {
  fifo="$(mktemp -u)"
  mkfifo $fifo
  while read -r line; do
    echo "[$(printf %-14s "${1}")] $line" | tee -a "${GLUSTERFS_LOG_CONT_DIR}/start_${1}"
  done <"$fifo" &
  "start_${1}" 1>"${fifo}" 2>&1
  if [[ "${1}" != "setup" ]]; then PROCS+=" ${1}"; fi
}

run_glusterd() {
  local rc=1
  local s=0
  local cmd=( /usr/sbin/glusterd -p /var/run/glusterd.pid --log-level "$GLUSTERFS_LOG_LEVEL" )

  echo -n "Starting glusterd"
  ${cmd[*]} &

  while [ $rc -ne 0 ] && [ $s -lt 30 ]; do
    ((s+=1))
    sleep 1
    gluster v info 1>/dev/null 2>&1
    rc=$?
  done

  if [ $rc -ne 0 ]; then
    echo "Timeout waiting for glusterd"
    exit 1
  fi
}

start_glusterd() {
  local mp_opt=""

  touch $GLUSTERFS_LOG_DIR/glusterd.log
  tail -n 0 -f $GLUSTERFS_LOG_DIR/glusterd.log &

  run_glusterd

  case "$GLUSTER_BRICKMULTIPLEX" in
    [nN] | [nN][Oo] | [oO][fF][fF] )
      mp_opt="off"
      ;;
    [yY] | [yY][Ee][Ss] | [oO][nN] )
      mp_opt="on"
      ;;
    *) echo "Invalid value '$GLUSTER_BRICKMULTIPLEX' for GLUSTER_BRICKMULTIPLEX"
      ;;
  esac

  gluster --mode=script volume set all cluster.brick-multiplex "$mp_opt" 2>&1 || echo "Enabling brick multiplexing failed"
  gluster --mode=script volume set all cluster.max-bricks-per-process 20 2>&1 || echo "Setting max bricks per process failed"
#  gluster --mode=script volume set all nfs.disable on 2>&1 || echo "Disabling NFS failed"
#  gluster --mode=script volume set all user.smb disable 2>&1 || echo "Disabling SMB failed"

  echo "Killing glusterd ... "
  rc=1
  s=0
  pid="$(pidof glusterd)"
  kill "$pid" 1>/dev/null 2>&1
  while [[ "x$pid" != "x" ]]; do
    if [[ $s -ge 30 ]]; then
      kill -9 "$pid" 1>/dev/null 2>&1
    fi
    ((s+=1))
    sleep 1
    pid="$(pidof glusterd)"
  done
  echo "OK"

  run_glusterd
}

# start rpcbind if it is not started yet
/usr/sbin/rpcinfo 127.0.0.1 >/dev/null 2>&1
rc="$?"
if [ $rc -ne 0 ]; then
  /sbin/rpcbind -w || exit 1
fi

startup "setup"
startup "glusterd"

rc=0
while [ $rc -eq 0 ]; do
  sleep 1
  for proc in ${PROCS}; do
    if [ -z "$(pidof "${proc}")" ]; then
      echo "${proc} process not found."
      rc=1
    fi
  done
done

echo "Exiting"
exit 1
