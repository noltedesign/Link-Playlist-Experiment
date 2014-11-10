class RenameUrlTable < ActiveRecord::Migration
  def change
    rename_table :urls, :feeds
  end
end
