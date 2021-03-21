#!/bin/bash

HOSTNAME=$1

timedatectl set-ntp true

(
echo g
echo n
echo  
echo  
echo +1M
echo n
echo  
echo  
echo  
echo t
echo 1
echo 4
echo w
) | fdisk /dev/vda

mkfs.xfs -f -b size=4k -s size=4k /dev/vda2

mount /dev/vda2 /mnt

pacstrap /mnt base linux-lts xfsprogs nano dhcpcd netctl sudo openssh grub qemu-guest-agent spice-vdagent

genfstab -U /mnt >> /mnt/etc/fstab

cat <<EOF > /mnt/install_part_2.sh

#!/bin/bash

HOSTNAME=$1

ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

sed -i '/#en_US.UTF-8 UTF-8/c\en_US.UTF-8 UTF-8' /etc/locale.gen
sed -i '/#ja_JP.UTF-8 UTF-8/c\ja_JP.UTF-8 UTF-8' /etc/locale.gen
locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo $HOSTNAME > /etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost\n127.0.1.1 ${HOSTNAME}.gensoukyou.neet.works ${HOSTNAME}" > /etc/hosts

echo -e "Description='enp1s0 dhcp'\nInterface=enp1s0\nConnection=ethernet\nIP=dhcp\nDHCPClient=dhcpcd" > /etc/netctl/enp1s0
sed -i '8s/.*/hostname/' /etc/dhcpcd.conf
netctl enable enp1s0
systemctl enable sshd
systemctl enable qemu-guest-agent
systemctl enable spice-vdagent
systemctl enable fstrim.timer

(
echo root
echo root
) | passwd root

mkinitcpio -P
grub-install /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg
exit
EOF

chmod +x /mnt/install_part_2.sh
arch-chroot /mnt /install_part_2.sh $HOSTNAME

rm /mnt/install_part_2.sh
umount /mnt

reboot
