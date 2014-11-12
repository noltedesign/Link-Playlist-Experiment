require "./app"
require "sinatra/activerecord/rake"

task :environment do
  require File.expand_path('config/environment', File.dirname(__FILE__))
end

Dir.glob('./lib/tasks/*.rake').each { |r| load r}