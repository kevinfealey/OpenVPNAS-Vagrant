#!/bin/bash

#your email address, which will be automatically registered with letsencrypt
emailAddress="joe@example.com"

#this is your domain that you'll use to connect to the vpn from the Internet
domain="example.com"

#the password you'll use to connect to the vpn as user "openvpn"
openvpnas_user_password="abc123"

#this is the domain that users/devices who connect to your vpn will belong to
network_domain="local"

apt-get update

#If VNC 
#apt-get install -y xfce4 xfce4-goodies tightvncserver

#install / set up nginx
echo "Installing Nginx"
apt-get -y install nginx
echo "Updating nginx configuration"
echo "Removing the default nginx index page"
echo "<html><body></body></html>" | tee /var/www/html/index.nginx-debian.html
echo "restarting nginx"
systemctl restart nginx

#setup let's encrypt (assuming nginx is running and publically accessible on port 80)
echo "Installing LetsEncrypt certbot"
add-apt-repository ppa:certbot/certbot -y
apt-get update
apt-get -y install python-certbot-nginx

#Get a new cert and set up certbot so we can get new certs in the future
echo "Setting up LetsEncrypt Certbot and generating a new cert"
certbot -n -m ${emailAddress} --no-redirect --no-eff-email --keep-until-expiring --agree-tos --nginx -d ${domain}"

#install openvpnas
echo "Downloading OpenVPN Access Server"
wget http://swupdate.openvpn.org/as/openvpn-as-2.1.12-Ubuntu16.amd_64.deb

echo "Installing OpenVPN Access Server"
dpkg -i openvpn-as-2.1.12-Ubuntu16.amd_64.deb
apt-get --yes install -f

#configure the first valid certificate from the last used
cd /usr/local/openvpn_as/scripts
echo "Setting up initial certificate"
echo "Updating private key"
sh confdba -mk cs.priv_key --value_file=/etc/letsencrypt/live/${domain}/privkey.pem
echo "Updating CA bund;e"
sh confdba -mk cs.ca_bundle --value_file=/etc/letsencrypt/live/${domain}/fullchain.pem
echo "Updating certificate"
sh confdba -mk cs.cert --value_file=/etc/letsencrypt/live/${domain}/cert.pem
echo "Restarting OpenVPNAS"
systemctl restart openvpnas.service

#set up the autrenew job
echo "Setting up cronjob for autorenew of certs"
crontab -l > /vagrant/mycron
echo "00 2 * * * certbot renew" >> /vagrant/mycron
crontab /vagrant/mycron
rm /vagrant/mycron

echo "Updating password for openvpn user."
echo "openvpn:${openvpnas_user_password}" | chpasswd

#configure OpenVPNAS
echo "Setting up openvpn"
cd /usr/local/openvpn_as/scripts
echo "setting hostname"
./sacli --key "host.name" --value "${domain}" ConfigPut

echo "setting client IP range"
./sacli --key "vpn.daemon.0.client.network" --value "192.168.2.0" ConfigPut
./sacli --key "vpn.daemon.0.client.netmask_bits" --value "24" ConfigPut

echo "setting up client DNS"
./sacli --key "vpn.client.routing.reroute_dns" --value "custom" ConfigPut
./sacli --key "vpn.server.dhcp_option.dns.0" --value "192.168.1.1" ConfigPut

echo "setting up private network access"
./sacli --key "vpn.server.routing.private_access" --value "nat" ConfigPut
./sacli --key "vpn.server.routing.private_network.0" --value "10.0.2.0/24" ConfigPut
./sacli --key "vpn.server.routing.private_network.1" --value "192.168.0.0/16" ConfigPut
./sacli --key "vpn.server.routing.private_network.2" --value "172.17.0.0/16" ConfigPut

echo "setting domain suffix"
./sacli --key "vpn.server.dhcp_option.adapter_domain_suffix" --value "${network_domain}" ConfigPut

echo "disabling autologin"
./sacli --user __DEFAULT__ --key prop_autologin UserPropDel

echo "make sure we're listening on port 443"
./sacli --key "vpn.server.daemon.tcp.port" --value "443" ConfigPut

echo "restarting OpenVPN"
systemctl restart openvpnas.service
