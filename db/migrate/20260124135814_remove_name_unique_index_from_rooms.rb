class RemoveNameUniqueIndexFromRooms < ActiveRecord::Migration[8.1]
  def change
    # Remove the unique index on name and room_type
    remove_index :rooms, name: "index_rooms_on_lower_name_and_room_type", if_exists: true
  end
end
