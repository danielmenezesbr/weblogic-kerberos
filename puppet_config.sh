#!/usr/bin/env bash
cat >/etc/krb5.conf <<EOF
[libdefaults]
default_realm = MSHOME.NET
rdns = no
dns_lookup_kdc = true
dns_lookup_realm = true

[realms]
MSHOME.NET = {
    kdc = winserver.mshome.net
    admin_server = winserver.mshome.net
}
EOF
sudo yum -y install krb5-workstation;
sudo echo "192.168.56.2 winserver.mshome.net" >>/etc/hosts
ln -sf /vagrant/puppet/hiera.yaml /etc/puppetlabs/code/hiera.yaml;
rm -rf /etc/puppetlabs/code/modules;
ln -sf /vagrant/puppet/environments/development/modules /etc/puppetlabs/code/modules;
ip="$(hostname -I | xargs)";
sed -i "s/address_change_me/$ip/g" /vagrant/puppet/hieradata/common.yaml;
#cd /home/vagrant
#wget https://github.com/danielmenezesbr/debugSSO/raw/master/debug1/target/debug1-1.war
#chown vagrant:vagrant /home/vagrant/debug1-1.war
