# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'guyirvine/ruby-dev'

  config.vm.provision :shell, path: 'bin/bootstrap.sh'

  config.vm.network 'forwarded_port', guest: 5002, host: 5002
  config.vm.network 'forwarded_port', guest: 8500, host: 8502

end
