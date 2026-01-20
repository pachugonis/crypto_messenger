class AddStatusToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :status, :integer, default: 0, null: false
    add_column :messages, :delivered_at, :datetime
    add_index :messages, :status
  end
end
