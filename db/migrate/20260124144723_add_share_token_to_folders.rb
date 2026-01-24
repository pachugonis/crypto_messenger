class AddShareTokenToFolders < ActiveRecord::Migration[8.1]
  def change
    add_column :folders, :share_token, :string
    add_index :folders, :share_token
    add_column :folders, :share_expires_at, :datetime
  end
end
