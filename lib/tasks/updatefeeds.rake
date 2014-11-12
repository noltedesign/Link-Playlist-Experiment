desc "Update feed items"
task :update_feeds => :environment do

  Feed.find_each do |feed|
    feed.destroy
  end

end
