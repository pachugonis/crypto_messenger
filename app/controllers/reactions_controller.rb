class ReactionsController < ApplicationController
  before_action :set_message
  before_action :authorize_room_access

  def create
    emoji = reaction_params[:emoji]
    existing_reaction = @message.reactions.find_by(user: current_user, emoji: emoji)
    
    if existing_reaction
      # If user clicked the same emoji, remove it (toggle off)
      existing_reaction.destroy
      @action = :removed
    else
      # Remove any other reactions from this user
      @message.reactions.where(user: current_user).destroy_all
      
      # Add new reaction
      @reaction = @message.reactions.build(user: current_user, emoji: emoji)
      if @reaction.save
        @action = :added
      else
        @action = :error
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to room_path(@message.room) }
    end
  end

  private

  def set_message
    @message = Message.find(params[:message_id])
  end

  def authorize_room_access
    room = @message.room
    unless room.participant?(current_user)
      redirect_to rooms_path, alert: t("common.access_denied")
    end
  end

  def reaction_params
    params.require(:reaction).permit(:emoji)
  end
end
