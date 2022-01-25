#!/bin/bash

HOSTNAME=$1

netctl stop $HOSTNAME-macvtap
netctl disable $HOSTNAME-macvtap
rm /etc/netctl/$HOSTNAME-macvtap
rm /etc/systemd/nspawn/$HOSTNAME.nspawn
ip link del ${HOSTNAME}0
