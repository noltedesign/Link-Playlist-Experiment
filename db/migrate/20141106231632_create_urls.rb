class CreateUrls < ActiveRecord::Migration
  def up
    create_table :urls do |t|
      t.string :userid
      t.string :link
      t.string :order
    end
  end

  def down
    drop_table :urls
  end
end