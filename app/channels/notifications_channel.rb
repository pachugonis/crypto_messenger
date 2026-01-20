class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
