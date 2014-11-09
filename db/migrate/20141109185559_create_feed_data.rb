class CreateFeedData < ActiveRecord::Migration
  def change
    add_column :urls, :feed_title, :string
    add_column :urls, :feed_link, :string
  end
end