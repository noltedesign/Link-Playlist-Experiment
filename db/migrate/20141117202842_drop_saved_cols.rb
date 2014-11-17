class DropSavedCols < ActiveRecord::Migration
  def change
    add_column :saved_items, :feed_item_id, :integer
    remove_column :saved_items, :feed_link
    remove_column :saved_items, :summary
    remove_column :saved_items, :title
    remove_column :saved_items, :item_url
    remove_column :saved_items, :published_on
    remove_column :saved_items, :guid
    remove_column :saved_items, :feed_type
  end
end
