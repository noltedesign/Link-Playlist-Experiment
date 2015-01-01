class FeedCategorizationS < ActiveRecord::Migration
  def change
    rename_table :feed_categorization, :feed_categorizations
  end
end
