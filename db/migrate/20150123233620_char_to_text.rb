class CharToText < ActiveRecord::Migration
  def change
    change_column :feed_items, :title, :text
    change_column :feed_items, :item_url, :text
    change_column :feed_items, :guid, :text
  end
end
