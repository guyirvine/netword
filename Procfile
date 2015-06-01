consul: sudo $(pwd)/consul/bin/consul agent -client 0.0.0.0 -bootstrap -ui-dir /vagrant/consul/ui -config-dir $(pwd)/consul/etc/bootstrap/
netword: bundle exec rerun 'ruby app.rb -p 5002 -o 0.0.0.0'
