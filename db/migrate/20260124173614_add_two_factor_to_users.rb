class AddTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_enabled, :boolean, default: false, null: false
    add_column :users, :otp_backup_codes, :text
    
    add_index :users, :otp_secret
  end
end
