#!/bin/sh

# Install pptpd
rpm -Uvh http://download.fedoraproject.org/pub/epel/beta/7/x86_64/epel-release-7-1.noarch.rpm
yum -y install ppp pptpd

# pptpd settings
echo 'localip 10.10.0.1' >> /etc/pptpd.conf
echo 'remoteip 10.10.0.100-199' >> /etc/pptpd.conf
echo 'ms-dns 8.8.8.8' >> /etc/ppp/options.pptpd
echo 'ms-dns 8.8.4.4' >> /etc/ppp/options.pptpd
echo 'USERNAME pptpd PASSWORD *' >> /etc/ppp/chap-secrets

# system ipv4 forward
sysctl_file=/etc/sysctl.conf
if grep -xq 'net.ipv4.ip_forward' $sysctl_file; then
  sed -i.bak -r -e "s/^.*net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/" $sysctl_file
else
  echo 'net.ipv4.ip_forward = 1' >> $sysctl_file
fi
sysctl -p

# firewalld
zone=public
firewall-cmd --permanent --new-service=pptp
cat >/etc/firewalld/services/pptp.xml<<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <port protocol="tcp" port="1723"/>
</service>
EOF
firewall-cmd --permanent --zone=$zone --add-service=pptp
firewall-cmd --permanent --zone=$zone --add-masquerade
firewall-cmd --reload

# start pptpd
systemctl start pptpd
systemctl enable pptpd.service