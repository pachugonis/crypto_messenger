class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :name, null: false
      t.integer :room_type, null: false, default: 0
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.integer :messages_count, default: 0
      t.integer :participants_count, default: 0

      t.timestamps
    end

    add_index :rooms, :room_type
    add_index :rooms, [ :room_type, :visibility ]
  end
end
