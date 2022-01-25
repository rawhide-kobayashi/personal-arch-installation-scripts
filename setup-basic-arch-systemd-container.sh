#!/bin/bash

HOSTNAME=$1

echo 'Create netctl config for host macvtap'
cat << EOF > /etc/netctl/$HOSTNAME-macvtap
Description='macvtap connection for passthrough to $HOSTNAME'
Interface=${HOSTNAME}0
Connection=macvlan
# The variable name is plural, but needs precisely one interface
BindsToInterfaces=br0
# MACVLAN Mode
Mode="bridge"
EOF

echo 'Enable host macvtap'
netctl enable $HOSTNAME-macvtap
echo 'Start host macvtap'
netctl start $HOSTNAME-macvtap

echo 'Create container .nspawn config'
cat << EOF > /etc/systemd/nspawn/$HOSTNAME.nspawn
[Network]
Interface=${HOSTNAME}0
[Files]
PrivateUsersOwnership=chown
[Exec]
PrivateUsers=pick
EOF

echo 'Bootstrap container'
pacstrap -c /var/lib/machines/$HOSTNAME base netctl dhcpcd nano cronie

echo 'Create network config for container'
cat << EOF > /var/lib/machines/$HOSTNAME/etc/netctl/$HOSTNAME-macvtap
Interface=${HOSTNAME}0
Connection=ethernet
IP=dhcp
DHCPClient=dhcpcd
EOF

echo 'Assign hostname to container'
echo $HOSTNAME > /var/lib/machines/$HOSTNAME/etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost\n127.0.1.1 ${HOSTNAME}.gensoukyou.neet.works ${HOSTNAME}" > /var/lib/machines/$HOSTNAME/etc/hosts

echo 'Enable network config via hacky cron workaround because idfk'
cat << EOF > /var/lib/machines/$HOSTNAME/var/spool/cron/root
@reboot netctl start $HOSTNAME-macvtap
EOF
chmod 600 /var/lib/machines/$HOSTNAME/var/spool/cron/root

echo 'Configure pacman for container'
cat << EOF > /var/lib/machines/$HOSTNAME/etc/pacman.d/mirrorlist
Server = http://patchouli.gensoukyou.neet.works:7878/\$repo/os/\$arch
EOF

sed -i '37s/.*/ParallelDownloads = 8/' /var/lib/machines/$HOSTNAME/etc/pacman.conf

sed -i '$ a \
\
Include = /etc/pacman.d/aurto' /var/lib/machines/$HOSTNAME/etc/pacman.conf

echo -e '[aurto]\nSigLevel = Optional TrustAll\nServer = http://satori.gensoukyou.neet.works/$repo/$arch\nServer = http://satori-ib.gensoukyou.neet.works/$repo/$arch' > /var/lib/machines/$HOSTNAME/etc/pacman.d/aurto

echo 'Start container, wait'
machinectl enable $HOSTNAME
machinectl start $HOSTNAME
sleep 5
echo 'Enable services, reboot'
systemd-run --wait --machine $HOSTNAME systemctl enable cronie
systemd-run --wait --machine $HOSTNAME passwd -l root
machinectl reboot $HOSTNAME
sleep 5
