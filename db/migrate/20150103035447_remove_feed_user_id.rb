class RemoveFeedUserId < ActiveRecord::Migration
  def change
    remove_column :feeds, :user_id
    remove_column :feeds, :order
  end
end
