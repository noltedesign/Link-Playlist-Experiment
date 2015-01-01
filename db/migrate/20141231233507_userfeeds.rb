class Userfeeds < ActiveRecord::Migration
  def change
    rename_table :feed_relation, :user_feeds
  end
end
