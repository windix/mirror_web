# RAILS_ROOT/racked.rb
require File.dirname(__FILE__) + '/config/environment'
require 'mongrel'
 
# Sinatra stuff
require 'services'
 
# Make sinatra play nice
set :environment, :development
disable :run, :reload
 
app = Rack::Builder.new {
  use Rails::Rack::Static
 
  # Anything urls starting with /tiny will go to Sinatra
  map "/services" do
    run Sinatra::Application
  end
 
  # Rest with Rails
  map "/" do
    run ActionController::Dispatcher.new
  end
}.to_app
 
Rack::Handler::Mongrel.run app, :Port => 3000, :Host => "0.0.0.0"
