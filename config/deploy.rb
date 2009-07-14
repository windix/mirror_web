set :application, "mirrorweb"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/douziorg/railsapp/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
set :repository, "ssh://win-server/~/git/mirror_web.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :copy

role :app, "douzi.org"
role :web, "douzi.org"
role :db,  "douzi.org", :primary => true

ssh_options[:port] = 2650
set :user, "douziorg"
set :use_sudo, false
#default_run_options[:pty] = true    # Solve 'stdin: is not a tty' prompt

namespace :deploy do
  task :restart do
    run "/home/douziorg/public_html/lab/restart_mongrel.php #{application}"  
  end

  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/delicious.yml #{release_path}/config/delicious.yml"
    run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
  end

end

after 'deploy:update_code', 'deploy:symlink_shared'
