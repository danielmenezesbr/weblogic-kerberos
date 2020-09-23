# -*- mode: ruby -*-
# vi: set ft=ruby :
$domain = "mshome.net"
$domain_ip_address = "192.168.56.2"
$ubuntu_ip_address = "192.168.56.14"

unless Vagrant.has_plugin?("vagrant-vbguest")
  puts 'Installing vagrant-vbguest Plugin...'
  system('vagrant plugin install vagrant-vbguest')
end
 
unless Vagrant.has_plugin?("vagrant-reload")
  puts 'Installing vagrant-reload Plugin...'
  system('vagrant plugin install vagrant-reload')
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 1.6.0"

require 'yaml'

boxes = YAML.load_file('./boxes.yaml')
common = YAML.load_file('./puppet/hieradata/common.yaml')
puppet_run = (common['orautils_nodemanagerautostart_enabled']) ? "once" : "always"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vbguest.auto_update = false
  
  config.vm.define "dc" do |config|
    config.vm.box = "cdaf/WindowsServerDC"
    config.vm.box_version = "2020.05.14"
    
    config.winrm.username = "vagrant"
    config.winrm.password = "vagrant"
    config.vm.guest = :windows
    config.vm.communicator = "winrm"
    config.winrm.timeout = 1800 # 30 minutes
    config.winrm.max_tries = 20
    config.winrm.retry_limit = 200
    config.winrm.retry_delay = 10
    config.vm.graceful_halt_timeout = 600
    
    config.vm.hostname = "winserver"
    config.vm.network "private_network", ip: "192.168.56.2"
    config.vm.provision "shell", path: "provision/uninstall-windefeder.ps1"
	config.vm.provision "shell", path: "provision/add-RSAT-AD.ps1"
    config.vm.provision "shell", path: "provision/ad.ps1"
    #config.vm.provision "shell", reboot: true
    config.vm.provision "ie", type: "shell", path: "provision/ie.ps1"
	config.vm.provision "weblogic-test", type: "shell", path: "provision/WebLogic-Test.ps1", run: "never"
	
  
    config.vm.provider :virtualbox do |v, override|
      v.memory = 1024
	  v.cpus = 1
	  v.gui = true
	  v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
	
	config.vbguest.auto_update = false
  end

  config.vm.define "weblogic" do |config|

    config.vm.box = boxes['virtualbox']['box']
    config.vm.box_version = "0.0.1"
    #config.vm.box_url = boxes['virtualbox']['box_url']

    config.vm.provider :vmware_fusion do |v, override|
      override.vm.box = boxes['vmware']['box']
      override.vm.box_url = boxes['vmware']['box_url']
    end

    config.vm.hostname = "clientlinux.mshome.net"
    config.vm.synced_folder "./provision", "/weblogicfiles"
    config.vm.synced_folder ".", "/vagrant"
    config.vm.synced_folder "./software", "/software"


    #config.vm.network :private_network, ip: "10.10.10.10", auto_config: false
	config.vm.network "private_network", ip: "192.168.56.14"
    config.vm.network "forwarded_port", guest: 7001, host: 7001, guest_ip: "10.0.2.15"
    config.vm.network "forwarded_port", guest: 7002, host: 7002
    config.vm.network "forwarded_port", guest: 8011, host: 8011, guest_ip: "123.123.22.21"
    config.vm.network "forwarded_port", guest: 8011, host: 8012, guest_ip: "123.123.22.22"
    config.vm.network "forwarded_port", guest: 8021, host: 8021
    config.vm.network "forwarded_port", guest: 8001, host: 8001
    config.vm.network "forwarded_port", guest: 18001, host: 18001

    config.vm.provider :virtualbox do |vb|	
      vb.customize ["modifyvm", :id, "--memory", "3072"]	
      vb.customize ["modifyvm", :id, "--cpus"  , 2]	
    end
    
    config.vm.provider :vmware_fusion do |vb|
      vb.vmx["numvcpus"] = "2"
      vb.vmx["memsize"] = "3072"
    end	

    config.vm.provision :shell, path: "./software/download.sh", env: {ORACLE_SSO_USERNAME:ENV['ORACLE_SSO_USERNAME'], ORCL_PWD:ENV['ORCL_PWD']}

    config.vm.provision :shell, path: "./puppet_config.sh"

    # in order to enable this shared folder, execute first the following in the host machine: mkdir log_puppet_weblogic && chmod a+rwx log_puppet_weblogic
    #config.vm.synced_folder "./log_puppet_weblogic", "/tmp/log_puppet_weblogic", :mount_options => ["dmode=777","fmode=777"]

    config.vm.provision "puppet", run: puppet_run do |puppet|
      puppet.environment_path     = "puppet/environments"
      puppet.environment          = "development"

      puppet.manifests_path       = "puppet/environments/development/manifests"
      puppet.manifest_file        = "site.pp"

      puppet.options           = [
                                  '--verbose',
                                  '--report',
                                  '--trace',
                                  '--debug',
#                                  '--parser future',
                                  '--strict_variables',
                                  '--hiera_config /vagrant/puppet/hiera.yaml'
                                 ]
      puppet.facter = {
        "environment"     => "development",
        "vm_type"         => "vagrant",
      }

    end
	
	config.vm.provision :shell, path: "./weblogickrb.sh"

  end
  
  config.vm.box_check_update = false
  config.vm.boot_timeout = 1200 # 20 minutes
end