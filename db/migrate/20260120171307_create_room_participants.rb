class CreateRoomParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :room_participants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.datetime :last_read_at
      t.boolean :muted, default: false

      t.timestamps
    end

    add_index :room_participants, [ :user_id, :room_id ], unique: true
    add_index :room_participants, [ :room_id, :user_id ]
  end
end
