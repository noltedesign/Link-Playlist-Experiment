class FeedCategoryColName < ActiveRecord::Migration
  def change
    rename_column :feed_categorizations, :category_id, :feed_category_id
  end
end
