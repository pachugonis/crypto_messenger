class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.integer :message_type, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :messages, [ :room_id, :created_at ]
    add_index :messages, :deleted_at
  end
end
