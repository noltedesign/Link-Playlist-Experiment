class AddSavedTypeColumn < ActiveRecord::Migration
  def change
    add_column :saved_items, :feed_type, :string
  end
end