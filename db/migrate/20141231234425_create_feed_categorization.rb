class CreateFeedCategorization < ActiveRecord::Migration
  def up
    create_table :feed_categorization do |t|
      t.string :feed_id
      t.string :category_id
      t.string :category_order
    end
  end

  def down
    drop_table :feed_categorization
  end
end
