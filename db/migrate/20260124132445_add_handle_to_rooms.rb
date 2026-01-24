class AddHandleToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :handle, :string
    add_index :rooms, :handle, unique: true, where: "handle IS NOT NULL"
  end
end
