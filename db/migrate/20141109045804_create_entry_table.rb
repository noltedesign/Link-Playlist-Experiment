class CreateEntryTable < ActiveRecord::Migration
  def up
    create_table :feed_items do |t|
      t.string :url_id
      t.string :name
      t.string :summary
      t.string :url
      t.string :published_on
      t.string :guid

      t.timestamps
    end
  end

  def down
    drop_table :feed_items
  end
end