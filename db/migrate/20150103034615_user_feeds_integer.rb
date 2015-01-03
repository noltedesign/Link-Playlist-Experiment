class UserFeedsInteger < ActiveRecord::Migration
  def change
    change_column :user_feeds, :feed_id, 'integer USING CAST("feed_id" AS integer)'
    change_column :user_feeds, :user_id, 'integer USING CAST("user_id" AS integer)'
  end
end
