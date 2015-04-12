class CharToText < ActiveRecord::Migration
  def change
    change_column :feed_items, :guid, :text
  end
end
