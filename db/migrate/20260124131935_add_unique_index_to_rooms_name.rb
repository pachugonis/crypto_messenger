class AddUniqueIndexToRoomsName < ActiveRecord::Migration[8.1]
  def up
    # Find and rename duplicate group/channel names before adding unique index
    # Group by lowercase name and room_type to find duplicates
    Room.where(room_type: [:group, :channel])
        .group_by { |room| [room.name.downcase, room.room_type] }
        .select { |_, rooms| rooms.size > 1 }
        .each do |_, rooms|
          # Keep the first one, rename others
          rooms[1..-1].each_with_index do |room, index|
            room.update_column(:name, "#{room.name} (#{index + 2})")
          end
        end
    
    # Add unique index for group and channel names (case-insensitive)
    # Personal chats are excluded from uniqueness constraint
    add_index :rooms, "LOWER(name), room_type", 
              unique: true, 
              where: "room_type IN (1, 2)",
              name: "index_rooms_on_lower_name_and_room_type"
  end
  
  def down
    remove_index :rooms, name: "index_rooms_on_lower_name_and_room_type"
  end
end
