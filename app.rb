# myapp.rb
require 'bcrypt'
require 'compass'
require 'feedjira'
require 'haml'
require 'sanitize'
require 'sass'
require 'sinatra'
require 'sinatra/activerecord'

require './config/environment' #database config
require './config/sass' #Configure Sass and Compass


set :environment, :development

class User < ActiveRecord::Base
  include BCrypt
  
  has_many :feeds, dependent: :destroy
  has_many :feed_items, through: :feeds
  has_many :saved_items, dependent: :destroy
end

class Feed < ActiveRecord::Base
  belongs_to :user 
  has_many :feed_items, dependent: :destroy, :inverse_of => :feed
  has_many :feed_categorizations
  has_many :feed_categories, through: :feed_categorizations
  
  serialize :feed_categories
  
  def pinterest?
    feed_type == 'pinterest'
  end
  
  def dribbble?
    feed_type == 'dribbble'
  end
end

class FeedCategory < ActiveRecord::Base
  has_many :feed_categorizations
  has_many :feeds, through: :feed_categorizations
end

class FeedCategorization < ActiveRecord::Base
  belongs_to :feed
  belongs_to :feed_categories
end

class FeedItem < ActiveRecord::Base
  belongs_to :feed, :inverse_of => :feed_items
  has_many :saved_items, dependent: :destroy 
  
  def saved_by_user?
    saved_items.any?
  end
end

class UserFeed < ActiveRecord::Base
  has_many :feeds
  has_many :users
end

class SavedItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :feed_item
end



enable :sessions



helpers do
  
  #start Session
  def loggedin?
    session[:loggedIN]
  end
  
  #define users
  def current_user
    if loggedin?
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
  @main_category = FeedCategory.find_by(category_name: 'main').feed_categorizations.order(category_order: :asc)
  
  haml :index
end


#signup / login
get '/login' do
  @body_class = 'login'
  haml :login
end

post '/signup' do
  
  @user = User.new(params[:users])
  
  @user.password_hash = BCrypt::Password.create(params[:password])
  
  if @user.save
    redirect '/#success'
  else
    redirect '/#fail'
  end
end



post '/login' do
  @body_class = 'login'
   
  @userlogemail = params[:email]
  @userlogpass = params[:password]
  
  @loggeduser =User.find_by_email(@userlogemail)
  
  @passhash = BCrypt::Password.new(@loggeduser.password_hash)
  
  if @passhash == @userlogpass
    session[:loggedIN]=true
    session[:loggedID]=@loggeduser.id
    
    redirect '/'
  else
    session[:loggedIN]=nil
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
  
  if loggedin?
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

post '/delete-account' do
  User.find(params[:user_id]).destroy()
  session.clear
  redirect '/'
end


#Add Feed

post '/add-feed' do
  
  @url = Feed.new(params[:urls])
  
  if @url.feed_type == 'pinterest'
    @url.link = "http://pinterest.com/#{@url.link}/feed.rss"
  end
  
  if @url.feed_type == 'dribbble'
    @url.link = "https://dribbble.com/#{@url.link}/shots/following.rss"
  end
  
  @feed_top = Feedjira::Feed.fetch_and_parse @url.link
  
  @url['feed_title'] = @feed_top.title
  @url['feed_link'] = @feed_top.url
  @url.save
  
  @feed_top.entries.first(80).each do |entry|
    
    @entry = FeedItem.new
    @entry.feed = @url
    @entry['title'] = entry.title
    @entry['summary'] = entry.summary
    @entry['item_url'] = entry.url
    @entry['published_on'] = entry.published
    @entry['guid'] = entry.id
    
    @entry.save
    
  end

  if @url.save
    redirect '/preferences#saved'
  else
    'Oops, something went wrong'
  end
end


#admin

get '/admin' do
  @body_class = 'admin'
  
  @admin = User.find_by(email: 'noltedesign@gmail.com')
  @adminid = session[:loggedID]
  
  if @adminid == @admin.id
    haml :admin
  else
    redirect '/'
  end
end


#Add Global Feed

post '/add-global' do
  
  @url = Feed.new(params[:urls])
  
  @categories =  params[:feed_categorization]['feed_category_id']
  
  @feed_top = Feedjira::Feed.fetch_and_parse @url.link
  
  @url['feed_title'] = @feed_top.title
  @url['feed_link'] = @feed_top.url
  @url.save
  
  @categories.each do |cat|
    @cat_link = FeedCategorization.new
    @cat_link['feed_id'] = @url.id
    @cat_link['feed_category_id'] = cat
    @cat_link.save
  end
  
  @feed_top.entries.first(80).each do |entry|
    
    @entry = FeedItem.new
    @entry.feed = @url
    @entry['title'] = entry.title
    @entry['summary'] = entry.summary
    @entry['item_url'] = entry.url
    @entry['published_on'] = entry.published
    @entry['guid'] = entry.id
    
    @entry.save
    
  end

  if @url.save
    redirect '/admin#success'
  else
    'Oops, something went wrong'
  end
end

#Add Categories

post '/add-feed-category' do
  @cat = FeedCategory.new
  @cat['category_name'] = params[:category_name]

  if @cat.save
    redirect '/admin#success'
  else
    'Oops, something went wrong'
  end
end

#Categories Order

post '/save-admin-order' do
  @feedorder = params['order']
  @feedorder = @feedorder.first.split(",")
    
  @feedorder.each_with_index do |o, i|
    toUpdate = FeedCategorization.find_by( id: o )
    toUpdate.category_order = i
    toUpdate.save
  end
  
  redirect '/admin#success'
  
  #put "#{@feedorder}"
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
  @saveIt.user = current_user
  @saveIt.feed_item = @originalItem
  @saveIt.save
  
  current_user.saved_items.order(created_at: :desc).drop(40).each do |gone|
    gone.destroy
  end
  
end

delete '/item/:id' do
  @togo = SavedItem.find_by_id(params[:id])
  @togo.destroy
end



