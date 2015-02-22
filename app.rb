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
  has_many :user_feeds
  has_many :feeds, through: :user_feeds
  has_many :feed_items, through: :feeds
  has_many :saved_items
end

class UserFeed < ActiveRecord::Base
  belongs_to :feed
  belongs_to :user
end

class Feed < ActiveRecord::Base
  has_many :users, through: :user_feeds 
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



# Index & Categories

#main
get '/' do
  @body_class = 'home main'
  @main_category = FeedCategory.find_by(category_name: 'main').feed_categorizations.order(category_order: :asc)
  
  haml :index
end

#tech
get '/tech' do
  @body_class = 'home tech'
  @main_category = FeedCategory.find_by(category_name: 'tech').feed_categorizations.order(category_order: :asc)
  
  haml :index
end

#Design
get '/design' do
  @body_class = 'home design'
  @main_category = FeedCategory.find_by(category_name: 'design').feed_categorizations.order(category_order: :asc)
  
  haml :index
end

#Entertainment
get '/entertainment' do
  @body_class = 'home entertainment'
  @main_category = FeedCategory.find_by(category_name: 'entertainment').feed_categorizations.order(category_order: :asc)
  
  haml :index
end

#polititcs
get '/politics' do
  @body_class = 'home politics'
  @main_category = FeedCategory.find_by(category_name: 'politics').feed_categorizations.order(category_order: :asc)
  
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
  
  @errors = ''
  
  if User.find_by_email( @user.email )  
    @errors += '<span>Email already exists</span>'
  end
  
  if User.find_by( userurl: @user.userurl ) 
    @errors += '<span>URL already exists</span>'
  end

  if @errors.length > 1
    @body_class = 'login'
    haml :login
  else
    if @user.save
      
      @loggeduser = User.find_by_email(@user.email)
      session[:loggedIN]=true
      session[:loggedID]=@loggeduser.id
      
      redirect '/preferences#success'
    else
      redirect '/#fail'
    end
  end
    
end

post '/login' do
  @body_class = 'login'
   
  @userlogemail = params[:email]
  @userlogpass = params[:password]
  
  @loggeduser = User.find_by_email(@userlogemail)
  
  if @loggeduser
    @passhash = BCrypt::Password.new(@loggeduser.password_hash)
  
    if @passhash == @userlogpass
      session[:loggedIN]=true
      session[:loggedID]=@loggeduser.id
      
      redirect '/'+@loggeduser.userurl
    else
      session[:loggedIN]=nil
      @body_class = 'login login-fail'
      @errorslog = '<span>Username or Password incorrect</span>'
      
      haml :login
    end
    
  else

    session[:loggedIN]=nil
    @body_class = 'login login-fail'
    @errorslog = '<span>Username or Password incorrect</span>'
      
    haml :login
  end
  

end

get '/logout' do
  session.clear
  redirect '/'
end



#Preferences
get '/preferences' do
  @body_class = 'preferences'
  @current_feed_order = current_user.user_feeds
  
  if loggedin?
    haml :preferences
  else
    redirect '/login'
  end
end


#Update password
post '/change-pass' do
  
  @newpass1 = params[:password1]
  @newpass2 = params[:password2]
  
  if @newpass1 = @newpass2
    
    if loggedin?
    
      @user = current_user
      @user.password_hash = BCrypt::Password.create(params[:password2])
      @user.save  
    
      @newpasserror = '<span class="success">Password updated!</span>'
      @current_feed_order = current_user.user_feeds
      haml :preferences
    else
      redirect '/login'
    end
  else
    @newpasserror = '<span>Passwords do not match.</span>'
    haml :preferences
  end

end

#Update Feed Order
post '/save-order' do
  @feedorder = params['order']
  @feedorder = @feedorder.first.split(",")
  
  @trashit = params['trash']
  @trashit = @trashit.first.split(",")
  
  @feedorder.each_with_index do |o, i|
    toUpdate = UserFeed.find_by( id: o )
    toUpdate.feed_order = i
    toUpdate.save
  end
  
  @trashit.each do |t|
    toTrash = UserFeed.find_by( id: t )
    toTrash.destroy
  end
  
  redirect '/preferences#success'
end

#Delete Account
post '/delete-account' do
  User.find(params[:user_id]).destroy()
  session.clear
  redirect '/'
end



#Add Feed
post '/add-feed' do

  @url = Feed.new(params[:urls])
  @user = params[:user_id]  
  if @url.feed_type == 'pinterest'
    @url.link = "http://pinterest.com/#{@url.link}/feed.rss"
  end
  
  if @url.feed_type == 'dribbble'
    @url.link = "https://dribbble.com/#{@url.link}/shots/following.rss"
  end
  
  @feedexists = Feed.find_by(link: @url.link)
  
  if @feedexists.present?
    
    @newlink = UserFeed.new
    
    @newlink['feed_id'] = @feedexists.id
    @newlink['user_id'] = @user
    @newlink.save
    redirect '/preferences#saved'
  
  else
    @feed_top = Feedjira::Feed.fetch_and_parse @url.link
    
    @url['feed_title'] = @feed_top.title
    @url['feed_link'] = @feed_top.url
    @url.save
    
    @newlink = UserFeed.new
    @newlink['feed_id'] = @url.id
    @newlink['user_id'] = @user
    @newlink.save
    
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
end



#User Feed
get '/:name' do |n|
  @body_class = 'user-feed feed-page user-' + n
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