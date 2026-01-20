class RoomParticipantsController < ApplicationController
  before_action :set_room
  before_action :set_participant, only: [ :update, :destroy ]
  before_action :authorize_admin, only: [ :create, :update, :destroy ]

  def create
    user = User.find_by(username: params[:username]) || User.find_by(email_address: params[:email])

    if user.nil?
      redirect_to @room, alert: t("common.no_results")
      return
    end

    if @room.participant?(user)
      redirect_to @room, alert: t("participants.already_member")
      return
    end

    @room.room_participants.create!(user: user, role: :member)
    redirect_to @room, notice: t("participants.added")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @room, alert: e.message
  end

  def update
    if @participant.update(participant_params)
      redirect_to @room, notice: t("participants.updated")
    else
      redirect_to @room, alert: @participant.errors.full_messages.join(", ")
    end
  end

  def destroy
    @participant.destroy
    redirect_to @room, notice: t("participants.removed")
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_participant
    @participant = @room.room_participants.find(params[:id])
  end

  def authorize_admin
    participant = @room.room_participants.find_by(user: current_user)
    unless participant&.admin? || participant&.owner?
      redirect_to @room, alert: t("common.access_denied")
    end
  end

  def participant_params
    params.require(:room_participant).permit(:role, :muted)
  end
end
