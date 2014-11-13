class AddFeedType < ActiveRecord::Migration
  def change
    add_column :feeds, :feed_type, :string
  end
end