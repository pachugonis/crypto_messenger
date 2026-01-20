class Admin::DashboardController < Admin::BaseController
  def index
    @total_users = User.count
    @total_rooms = Room.count
    @total_messages = Message.count
    @active_users = User.where("updated_at > ?", 7.days.ago).count
    @storage_used = ActiveStorage::Blob.sum(:byte_size)

    @rooms_by_type = {
      personal_chats: Room.personal_chat.count,
      groups: Room.group.count,
      channels: Room.channel.count
    }

    @recent_users = User.order(created_at: :desc).limit(5)
  end
end
