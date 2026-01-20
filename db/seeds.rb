# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating users..."

# Create admin user
admin = User.find_or_create_by!(email_address: "admin@example.com") do |user|
  user.username = "admin"
  user.password = "password123"
  user.role = :admin
end
puts "  Admin: #{admin.email_address} (password: password123)"

# Create regular users
users = []
5.times do |i|
  user = User.find_or_create_by!(email_address: "user#{i + 1}@example.com") do |u|
    u.username = "user#{i + 1}"
    u.password = "password123"
    u.role = :user
  end
  users << user
  puts "  User: #{user.email_address} (password: password123)"
end

puts "\nCreating rooms..."

# Create a group
group = Room.find_or_create_by!(name: "Общая группа") do |room|
  room.room_type = :group
  room.description = "Общая группа для всех пользователей"
  room.visibility = :private_room
end

# Add all users to the group
[ admin, *users ].each_with_index do |user, index|
  RoomParticipant.find_or_create_by!(user: user, room: group) do |p|
    p.role = index == 0 ? :owner : :member
  end
end
puts "  Group: #{group.name}"

# Create a public channel
channel = Room.find_or_create_by!(name: "Объявления") do |room|
  room.room_type = :channel
  room.description = "Канал с важными объявлениями"
  room.visibility = :public_room
end

RoomParticipant.find_or_create_by!(user: admin, room: channel) do |p|
  p.role = :owner
end
puts "  Channel: #{channel.name}"

# Create some messages
puts "\nCreating messages..."
if group.messages.empty?
  Message.create!(room: group, user: admin, content: "Добро пожаловать в группу!")
  Message.create!(room: group, user: users[0], content: "Привет всем!")
  Message.create!(room: group, user: users[1], content: "Рад присоединиться!")
  puts "  Created sample messages"
end

# Create a folder for admin
puts "\nCreating folders..."
folder = Folder.find_or_create_by!(user: admin, name: "Документы")
puts "  Folder: #{folder.name}"

puts "\nSeeding complete!"
