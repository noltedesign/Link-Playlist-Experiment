class AddSavedTable < ActiveRecord::Migration
  def up
    create_table :saved_items do |t|
      t.string :user_id
      t.string :feed_title
      t.string :feed_link
            
      t.string :title
      t.string :summary
      t.string :item_url
      t.string :published_on
      t.string :guid
      
      t.timestamps
    end
  end

  def down
    drop_table :feed_items
  end
end