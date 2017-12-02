OpenVPNAS-Vagrant

1. Clone this repo
2. Open "provisionVM.sh" in a text editor
3. Update the variables at the top of the file
4. Review the network variables set toward the bottom of the "provisionVM.sh" file (the ones that start with ./sacli -- those are configuring openvpn"
5. Open "vagrant_vars.yaml" in a text editor
6. Update the variables as necessary. In particular, make sure the "network gateway" and "host_interface" are right. The other defaults should be ok.
7. From the directory that contains "Vagrantfile", run `vagrant up`. 

The script will probably take several minutes to finish (5-10). Once it's done, OpenVPN should be accessible on your local network at https://<VMs_IP> (note that you should receive certificate errors, since the cert is configured to your public domain. If your firewall port forwarding rules are configured correctly (TCP 80 and 443, UDP 1194), it should also be accessible at https://<yourdomain>.

OpenVPN Administration is accessible at the same URLs with "/admin" added to the end. 

http://<yourIP> should show a blank page. A web server (nginx) is listening on port 80 and serving a single static blank HTML page. The serveris required (as far as I know) for letsencrypt to work.

Every day at 2am, your VM will check if your certificate is expected to expire within 30 days. If it is, the certificate will be renewed automatically. If it is not, nothing will happen.


