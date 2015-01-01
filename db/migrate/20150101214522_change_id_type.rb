class ChangeIdType < ActiveRecord::Migration
  def change
    change_column :feed_categorizations, :feed_id, 'integer USING CAST("feed_id" AS integer)'
    change_column :feed_categorizations, :category_id, 'integer USING CAST("category_id" AS integer)'
  end
end
