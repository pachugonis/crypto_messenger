class RoomsController < ApplicationController
  before_action :set_room, only: [ :show, :edit, :update, :destroy, :leave, :mark_read ]
  before_action :authorize_room_access, only: [ :show, :edit, :update, :destroy ]

  def index
    @rooms = current_user.rooms.includes(:users, :messages).order(updated_at: :desc)
    @personal_chats = @rooms.select(&:personal_chat?)
    @groups = @rooms.select(&:group?)
    @channels = @rooms.select(&:channel?)
  end

  def show
    @messages = @room.messages.not_deleted.chronological.includes(:user).last(50)
    @participant = @room.room_participants.find_by(user: current_user)
    @participant&.mark_as_read!
  end

  def new
    @room = Room.new(room_type: params[:type] || :group)
  end

  def create
    @room = Room.new(room_params)

    Room.transaction do
      @room.save!
      @room.room_participants.create!(user: current_user, role: :owner)

      # For personal chats, add the other user
      if @room.personal_chat? && params[:user_id].present?
        other_user = User.find(params[:user_id])
        @room.room_participants.create!(user: other_user, role: :member)
      end
    end

    redirect_to @room, notice: t("rooms.messages.created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    if @room.update(room_params)
      redirect_to @room, notice: t("rooms.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @room.destroy
    redirect_to rooms_path, notice: t("rooms.messages.deleted")
  end

  def leave
    participant = @room.room_participants.find_by(user: current_user)
    participant&.destroy
    redirect_to rooms_path, notice: t("rooms.messages.left")
  end

  def mark_read
    participant = @room.room_participants.find_by(user: current_user)
    participant&.mark_as_read!
    head :ok
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def authorize_room_access
    unless @room.participant?(current_user) || @room.visibility_public_room?
      redirect_to rooms_path, alert: t("common.access_denied")
    end
  end

  def room_params
    params.require(:room).permit(:name, :description, :room_type, :visibility)
  end
end
