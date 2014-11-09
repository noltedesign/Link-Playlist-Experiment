configure do
  set :haml, {:format => :html5}
  set :scss, {:style => :compressed}
  # Compass.add_project_configuration(File.join(settings.root, 'config', 'compass.rb'))
end

get '/css/:name.css' do
  content_type 'text/css', :charset => 'utf-8'
  scss :"/assets/css/#{params[:name]}", Compass.sass_engine_options
end