require 'rake/testtask'

task :change do
  `git add . && git commit -m 'Change' && scp -r public/* girvine@192.168.1.73:/usr/share/nginx/www/quote`
end

task :push do
  `git push`
  `ssh girvine@192.168.1.73 'cd /guyirvine.com/quote && git pull'`
  # `scp -r public/* girvine@192.168.1.73:/usr/share/nginx/www/quote`
end

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc 'Run tests'
task :default => :test
