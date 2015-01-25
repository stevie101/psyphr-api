set :repository, 'file:///Users/stevie/projects/sec/trunk'
set :local_repository,  "file://."
set :scm, :git
set :deploy_via, :copy
set :checkout, "export"
set :use_sudo, true
set :deploy_to, "/var/www/cloudsec"
role :app, '192.168.1.93'
# role :web, '192.168.1.96'
role :db, '192.168.1.93', :primary => true