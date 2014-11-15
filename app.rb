# myapp.rb
require 'bcrypt'
require 'compass'
require 'feedjira'
require 'haml'
require 'sass'
require 'sinatra'
require 'sinatra/activerecord'

require './config/environment' #database config
require './config/sass' #Configure Sass and Compass



set :environment, :development

class User < ActiveRecord::Base
  has_many :feeds
  has_many :feed_items, through: :feeds
  has_many :saved_items
end

class Feed < ActiveRecord::Base
  belongs_to :user 
  has_many :feed_items, dependent: :destroy, :inverse_of => :feed
end

class FeedItem < ActiveRecord::Base
  belongs_to :feed, :inverse_of => :feed_items
end

class SavedItem < ActiveRecord::Base
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
  @current_feed_order = current_user.feeds(:order => 'order')
  
  if admin?
    haml :preferences
  else
    redirect '/login'
  end
end

post '/save-order' do
  @feedorder = params['order']
  @feedorder = @feedorder.first.split(",")
  
  @trashit = params['trash']
  @trashit = @trashit.first.split(",")
  
  @feedorder.each_with_index do |o, i|
    toUpdate = Feed.find_by( id: o )
    toUpdate.order = i
    toUpdate.save
  end
  
  @trashit.each do |t|
    toTrash = Feed.find_by( id: t )
    toTrash.destroy
  end
  
  redirect '/preferences#success'
end

#Add Feed

post '/add-feed' do
  
  @url = Feed.new(params[:urls])
  
  if @url.feed_type == 'pinterest'
    @url.link = "http://pinterest.com/#{@url.link}/feed.rss"
    @feed_top = Feedjira::Feed.fetch_and_parse @url.link
  else 
    @feed_top = Feedjira::Feed.fetch_and_parse @url.link
  end
  
  @url['feed_title'] = @feed_top.title
  @url['feed_link'] = @feed_top.url
  @url.save
  
  @feed_top.entries.first(80).each do |entry|
    @entry = FeedItem.new
    @entry['feed_id'] = @url.id
    @entry['title'] = entry.title
    @entry['summary'] = entry.summary
    @entry['item_url'] = entry.url
    @entry['published_on'] = entry.published
    @entry['guid'] = entry.id
    
    @entry.save
    
  end

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

  haml :userfeed
end

post '/save-item' do
  @originalItem = FeedItem.find_by_id(params[:id])
  
  @saveIt = SavedItem.new
    @saveIt['user_id'] = current_user.id
    @saveIt['feed_title'] = @originalItem.feed.feed_title
    @saveIt['feed_type'] = @originalItem.feed.feed_type
    
    @saveIt['feed_link'] = @originalItem.feed.feed_link
    @saveIt['title'] = @originalItem.title
    @saveIt['summary'] = @originalItem.summary
    @saveIt['item_url'] = @originalItem.item_url
    @saveIt['published_on'] = @originalItem.published_on
    @saveIt['guid'] = @originalItem.guid
  
    @saveIt.save
  
  current_user.saved_items.order(created_at: :desc).drop(40).each do |gone|
    gone.destroy
  end
end

post '/delete-item' do
  @togo = SavedItem.find_by_id(params[:id])
  @togo.destroy
end