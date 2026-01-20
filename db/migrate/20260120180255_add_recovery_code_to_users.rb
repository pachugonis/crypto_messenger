class AddRecoveryCodeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :recovery_code_digest, :string
    add_index :users, :recovery_code_digest
  end
end
