class Admin::StatisticsController < Admin::BaseController
  def index
    @daily_messages = Message.where("created_at > ?", 30.days.ago)
                             .group("DATE(created_at)")
                             .count

    @daily_users = User.where("created_at > ?", 30.days.ago)
                       .group("DATE(created_at)")
                       .count

    @top_rooms = Room.left_joins(:messages)
                     .group(:id)
                     .order("COUNT(messages.id) DESC")
                     .limit(10)
                     .select("rooms.*, COUNT(messages.id) as messages_total")

    @storage_by_type = ActiveStorage::Blob.group(:content_type)
                                          .sum(:byte_size)
  end
end
