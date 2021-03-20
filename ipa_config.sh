#!/bin/bash

ADMINUSER=$1
ADMINUSERPASS=$2

sed -i '$ a \
\
Include = /etc/pacman.d/aurto' /etc/pacman.conf

echo -e '[aurto]\nSigLevel = Optional TrustAll\nServer = http://satori.gensoukyou.neet.works\$repo\$arch\nServer = http://satori-ib.gensoukyou.neet.works\$repo\$arch' > /etc/pacman.d/aurto

pacman -Sy chrony freeipa-client python-gssapi python-nss python-yubico yp-tools certmonger oddjob python-ipaclient python-ipalib

mkdir /etc/krb5.conf.d
ln -sf /usr/bin/true /usr/bin/authselect
mkdir /etc/authselect
cp /etc/nsswitch.conf /etc/authselect/user-nsswitch.conf
mkdir /usr/share/ipa/client
mkdir -p /usr/share/ipa/client
echo -e '[libdefaults]\n    spake_preauth_groups = edwards25519' > /usr/share/ipa/client/freeipa.template

(
echo y
echo 0.north-america.pool.ntp.org,1.north-america.pool.ntp.org,2.north-america.pool.ntp.org,3.north-america.pool.ntp.org
echo  
echo y
echo $ADMINUSER
echo $ADMINUSERPASS
) | ipa-client-intall --no-nisdomain

sed -i '82s/.*/%wheel ALL=(ALL) ALL/' /etc/sudoers

sed -i '4s/.*/passwd: sss files systemd/' /etc/nsswitch.conf 
sed -i '5s/.*/group: sss files [SUCCESS=merge] systemd/' /etc/nsswitch.conf
sed -i '6s/.*/shadow: files sss/' /etc/nsswitch.conf
sed -i '14s/.*/services: sss files/' /etc/nsswitch.conf
sed -i '18s/.*/netgroup: sss files/' /etc/nsswitch.conf
sed -i '18 a automount: sss files' /etc/nsswitch.conf
sed -i '19 a sudoers: files sss' /etc/nsswitch.conf

sed -i '5 a auth       sufficient                  pam_sss.so           forward_pass' /etc/pam.d/system-auth
sed -i '15 a account    [default=bad success=ok user_unknown=ignore authinfo_unavail=ignore] pam_sss.so' /etc/pam.d/system-auth
sed -i '21 a password   sufficient                  pam_sss.so           use_authtok' /etc/pam.d/system-auth
sed -i '26 a session    required                    pam_mkhomedir.so skel=/etc/skel/ umask=0077' /etc/pam.d/system-auth
sed -i '29 a session    optional                    pam_sss.so' /etc/pam.d/system-auth

sed -i '2 a auth            sufficient      pam_sss.so   forward_pass' /etc/pam.d/su
sed -i '7 a account         [default=bad success=ok user_unknown=ignore authinfo_unavail=ignore] pam_sss.so' /etc/pam.d/su
sed -i '9 a session         optional        pam_sss.so' /etc/pam.d/su

sed -i '1 a auth            sufficient      pam_sss.so' /etc/pam.d/sudo
sed -i '1 a password        sufficient      pam_sss.so' /etc/pam.d/passwd

sed -i '12 a ldap_sudo_search_base = ou=wheel,dc=gensoukyou,dc=neet,dc=works' /etc/sssd/sssd.conf
