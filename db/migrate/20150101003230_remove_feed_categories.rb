class RemoveFeedCategories < ActiveRecord::Migration
  def change
    remove_column :feeds, :feed_categories
  end
end