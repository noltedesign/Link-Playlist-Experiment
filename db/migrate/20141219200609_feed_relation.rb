class FeedRelation < ActiveRecord::Migration
  def up
    create_table :feed_relation do |t|
      t.string :feed_id
      t.string :user_id
    end
  end

  def down
    drop_table :feed_relation
  end
end
