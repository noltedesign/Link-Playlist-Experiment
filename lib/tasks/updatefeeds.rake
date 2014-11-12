desc "Update feed items"
task :update_feeds => :environment do

  Feed.find_each do |feed|
  
    updated_feed = Feedjira::Feed.fetch_and_parse feed.link

    updated_feed.entries.each do |entry|
      unless feed.feed_items.exists?( :guid => entry.id )
        entry_new = FeedItem.new
        entry_new['feed_id'] = feed.id
        entry_new['title'] = entry.title
        entry_new['summary'] = entry.summary
        entry_new['item_url'] = entry.url
        entry_new['published_on'] = entry.published
        entry_new['guid'] = entry.id
        
        entry_new.save
      end
    end
    
    feed.feed_items.order(published_on: :desc).drop(80).each do |gone|
      gone.destroy
    end
    
    
  end

end
