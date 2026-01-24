class RoomChannel < ApplicationCable::Channel
  def subscribed
    @room = Room.find(params[:room_id])

    if @room.participant?(current_user) || @room.visibility_public_room?
      stream_for @room
      stream_from "room_#{@room.id}"
      
      # Mark undelivered messages as delivered when user connects
      mark_messages_as_delivered
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  def typing
    RoomChannel.broadcast_to(
      @room,
      {
        type: "typing",
        user_id: current_user.id,
        username: current_user.username
      }
    )
  end

  def stop_typing
    RoomChannel.broadcast_to(
      @room,
      {
        type: "stop_typing",
        user_id: current_user.id
      }
    )
  end
  
  # Called from client when message is received
  def message_delivered(data)
    message = Message.find_by(id: data['message_id'])
    return unless message
    return if message.user_id == current_user.id # Don't mark own messages
    
    message.mark_as_delivered
  end
  
  private
  
  def mark_messages_as_delivered
    # Mark all sent messages (not by current user) as delivered
    @room.messages
         .where.not(user: current_user)
         .where(status: Message.statuses[:sent])
         .find_each do |message|
      message.mark_as_delivered
    end
  end
end
