class FeedCategories < ActiveRecord::Migration
  def up
    create_table :feed_categories do |t|
      t.string :category_name
    end
  end

  def down
    drop_table :feed_categories
  end
end
