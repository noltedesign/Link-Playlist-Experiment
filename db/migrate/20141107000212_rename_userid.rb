class RenameUserid < ActiveRecord::Migration
  def change
    rename_column :urls, :userid, :user_id
  end
end
