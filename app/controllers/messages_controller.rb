class MessagesController < ApplicationController
  before_action :set_room
  before_action :set_message, only: [ :update, :destroy ]
  before_action :authorize_write, only: [ :create ]
  before_action :authorize_message_owner, only: [ :update, :destroy ]

  def create
    @message = @room.messages.build(message_params)
    @message.user = current_user

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @room }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { room: @room, message: @message }) }
        format.html { redirect_to @room, alert: @message.errors.full_messages.join(", ") }
      end
    end
  end

  def update
    if @message.update(message_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @room }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @message.soft_delete!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @room }
    end
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_message
    @message = @room.messages.find(params[:id])
  end

  def authorize_write
    unless @room.can_write?(current_user)
      redirect_to @room, alert: t("common.access_denied")
    end
  end

  def authorize_message_owner
    unless @message.user == current_user
      redirect_to @room, alert: t("common.access_denied")
    end
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
