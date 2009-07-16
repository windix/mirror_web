namespace :services do
  desc "Start sinatra web services used by mirrorweb"
  task(:start => :environment) do
    exec "ruby #{RAILS_ROOT}/other/chardet_web/services.rb -p #{SERVICES_PORT}"
  end
end
