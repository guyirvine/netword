require 'rake/testtask'

task :getdb do
  `scp dexter.guyirvine.com:/guyirvine.com/backup/netword.sql.latest.tar.bz2 ./sql`
  `cd sql && tar -jxf netword.sql.latest.tar.bz2 && rm netword.sql.latest.tar.bz2`
end

task :db do
  `createdb netword`
  `psql -f sql/netword.sql netword`
  `psql -f sql/create_tables.sql netword`
  `psql -f sql/seed.sql netword`
end

task :rdb do
  `dropdb netword`
  Rake::Task["db"].invoke
end


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
