class RoomChannel < ApplicationCable::Channel
  def subscribed
    @room = Room.find(params[:room_id])

    if @room.participant?(current_user) || @room.visibility_public_room?
      stream_for @room
      stream_from "room_#{@room.id}"
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
end
