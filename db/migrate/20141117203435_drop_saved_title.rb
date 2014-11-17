class DropSavedTitle < ActiveRecord::Migration
  def change
    remove_column :saved_items, :feed_title
  end
end
