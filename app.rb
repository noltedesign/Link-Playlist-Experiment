# myapp.rb
require 'bcrypt'
require 'compass'
require 'feedjira'
require 'haml'
require 'sass'
require 'sinatra'
require 'sinatra/activerecord'

require './config/environments' #database config
require './config/sass' #Configure Sass and Compass


class User < ActiveRecord::Base
  has_many :urls
end

class Url < ActiveRecord::Base
  belongs_to :user
end


enable :sessions


helpers do
  
  #start Session
  def admin?
    session[:admin]
  end
  
  #define users
  def current_user
    if admin?
      user_id = session[:loggedID]
      user = User.find_by_id(user_id)
    end
  end
  
  #escape HTML
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
  #remove HTML tags
  def remove_html_tags( text )
    text.presence || text = ' '
    text.gsub(/<(script|style)[^>]*>.*<\/\1>/im, '').gsub( %r{</?[^>]+?>}, '' )[0..200] << "..."
  end
  
end



# Index
get '/' do
  @body_class = 'home'
  @listu = User.order("created_at DESC")
  
  #make homepage my list
  @userfeed = User.find_by_id(17)
  @feeds = Array.new
  @userfeed.urls.each do |rssfeed|
    @feeds.push( Feedjira::Feed.fetch_and_parse rssfeed.link )
  end
  
  haml :index
end


#signup / login
get '/signup' do
  @body_class = 'signup'
  haml :signup
end

post '/signup' do
  @user = User.new(params[:users])
  if @user.save
    redirect '/#success'
  else
    redirect '/#fail'
  end
end

get '/login' do
  haml :login
end

post '/login' do
  @body_class = 'login'
   
  @userlogemail = params[:email]
  @userlogpass = params[:password]
  
  @loggeduser =User.find_by_email(@userlogemail)
  
  if @loggeduser.password == @userlogpass
    session[:admin]=true
    session[:loggedID]=@loggeduser.id
    
    redirect '/'
  else
    session[:admin]=nil
    "Doh, wrong password"
  end
end

get '/logout' do
  session.clear
  redirect '/'
end

#Preferences
get '/preferences' do
  @body_class = 'preferences'
  @current_feed_order = current_user.urls(:order => 'order')
  
  if admin?
    haml :preferences
  else
    redirect '/login'
  end
end

post '/save-order' do
  @feedorder = params['order']
  @feedorder = @feedorder.first.split(",")
  
  @feedorder.each_with_index do |o, i|
    toUpdate = Url.find_by( id: o )
    toUpdate.order = i
    toUpdate.save
  end
  
  redirect '/preferences#success'
end

#Add Feed
get '/add-feed' do
   @body_class = 'add-feed'
  if admin?
    haml :add_feed
  else
    redirect '/login'
  end
end

post '/add-feed' do
  @url = Url.new(params[:urls])
  if @url.save
    redirect '/#saved'
  else
    'Oops, something went wrong'
  end
end

#User Feed
get '/:name' do |n|
  @body_class = 'feed-page user-' + n
  @userfeed = User.where(userurl: n).first
  @feeds = Array.new
  
  @userfeed.urls.each do |rssfeed|
    @feeds.push( Feedjira::Feed.fetch_and_parse rssfeed.link )
  end

  haml :userfeed

end