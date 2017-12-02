# -*- mode: ruby -*-
# vi: set ft=ruby :


require 'yaml'
settings = YAML.load_file './vagrant_vars.yaml'

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

      if (defined?(settings['guest_hostname']).nil?)
                # do nothing if hostname var is not defined
        else
                config.vm.hostname = settings['guest_hostname']
        end

        config.vm.box_check_update = true

        # Create a public network, which generally matched to bridged network.
        # Bridged networks make the machine appear as another physical device on
        # your network.
        if (defined?(settings['guest_mac_addr']).nil?)
                config.vm.network "public_network"
        elsif (defined?(settings['host_interface']).nil?)
                print "No network interface set in vagrant_vars.yml\n"
                config.vm.network "public_network", mac: settings['guest_mac_addr']
        else
                print "Using network interface: " + settings['host_interface'] + ".\n"
                config.vm.network "public_network", mac: settings['guest_mac_addr'], bridge: settings['host_interface']
        end


        $gatewayUpdate_script = <<SCRIPT
                #update gateway to allow it to respond outside of localhost
                #if there is a current default gateway set to $VAGRANT_GATEWAY
                echo "Setting default route."
                if [ -n  "`ip route | grep 'default via '$VAGRANT_GATEWAY`" ]; then
                        route del default gw $VAGRANT_GATEWAY
                        route add default gw $NETWORK_GATEWAY
                        echo "Default route set."
                else
                        echo "Default route already set correctly."
                fi
SCRIPT
 if (settings['setupDuo'] == "true")
                config.vm.provision "shell", path: "setupDuo.sh", env: {"DUO_IKEY" => settings['duo_integration_key'], "DUO_SKEY" => settings['duo_secret_key'], "DUO_APIHOST" => settings['duo_api_hostname']}
        end

        if (settings['networkAccess'] == "true")
                #update gateway to allow it to respond outside of localhost -- comment this line out if you only want access to the services via IP/hostname from localhost
                config.vm.provision "shell", run: "always", inline: $gatewayUpdate_script, env: {"VAGRANT_GATEWAY" => settings['vagrant_gateway'], "NETWORK_GATEWAY" => settings['network_gateway']}
        end

        if (settings['localhostAccess'] == "true")
                #If you want to access these services via localhost (i.e. http://localhost:5601 for Kibana), set localhostAccess to true. Otherwise use the above to access services via the guest hostname or IP
                config.vm.network "forwarded_port", guest: 8443, host: 8443 #web interface
                config.vm.network "forwarded_port", guest: 8080, host: 8080  #inform
        end

   config.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 2
   end
##########################################################################

  config.vm.provision "shell", path: "provisionVM.sh"

end
