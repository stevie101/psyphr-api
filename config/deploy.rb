# require "bundler/capistrano"
require "rvm/capistrano"

set :application, 'sec-server'
default_run_options[:pty] = true
set :ssh_options, { :forward_agent => true }
set :repository, 'git@github.com:stevie101/sec-server.git'
set :user, "user"
set :port, 22
set :use_sudo, false
set :rvm_type, :system
set :deploy_to, "/home/user/apps/#{application}/"
set :scm, :git
set :branch, "master"
set :deploy_via, :copy
set :rails_env, "development"
set :normalize_asset_timestamps, false

role :app, "192.168.1.99"
# role :app, "54.72.53.19"
role :db, "192.168.1.99", :primary => true

namespace :deploy do
  task :symlink_shared do
    run "ln -s #{shared_path}/system/config/database.yml #{release_path}/config/database.yml"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'

# set :application, "set your application name here"
# set :repository,  "set your repository location here"
# 
# # set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# # Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
# 
# role :web, "your web-server here"                          # Your HTTP server, Apache/etc
# role :app, "your app-server here"                          # This may be the same as your `Web` server
# role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"
# 
# # if you want to clean up old releases on each deploy uncomment this:
# # after "deploy:restart", "deploy:cleanup"
# 
# # if you're still using the script/reaper helper you will need
# # these http://github.com/rails/irs_process_scripts
# 
# # If you are using Passenger mod_rails uncomment this:
# # namespace :deploy do
# #   task :start do ; end
# #   task :stop do ; end
# #   task :restart, :roles => :app, :except => { :no_release => true } do
# #     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
# #   end
# # end