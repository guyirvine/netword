#!/usr/bin/env bash

su -c '/usr/bin/createuser -s vagrant' postgres
echo 'cd /vagrant' >> /home/vagrant/.bashrc
psql -c "ALTER ROLE vagrant WITH PASSWORD 'vagrant'" template1

echo 'nameserver 10.0.2.15' > /etc/resolv.conf
echo 'nameserver 10.0.2.3' >> /etc/resolv.conf
echo 'search service.consul' >> /etc/resolv.conf

cd /vagrant

bundle install
