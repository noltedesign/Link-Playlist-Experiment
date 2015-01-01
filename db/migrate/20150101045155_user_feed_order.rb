class UserFeedOrder < ActiveRecord::Migration
  def change
    add_column :user_feeds, :feed_order, :string
  end
end
