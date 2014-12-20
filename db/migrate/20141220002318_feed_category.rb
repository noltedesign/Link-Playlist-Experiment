class FeedCategory < ActiveRecord::Migration
  def change
    add_column :feeds, :feed_categories, :string
  end
end
