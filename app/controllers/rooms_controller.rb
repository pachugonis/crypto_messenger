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
    @messages = @room.messages.not_deleted.chronological.includes(:user, :message_reads).last(50)
    @participant = @room.room_participants.find_by(user: current_user)
    @participant&.mark_as_read!
    
    # Mark all messages in this room as read by current user
    mark_messages_as_read
  end

  def new
    @room = Room.new(room_type: params[:type] || :group)
  end

  def create
    @room = Room.new(room_params)

    Room.transaction do
      # For personal chats, check if chat already exists
      if @room.personal_chat? && params[:user_id].present?
        # Support both user_id (integer) and username (string)
        other_user = if params[:user_id].to_i.to_s == params[:user_id].to_s
                       User.find(params[:user_id])
                     else
                       User.find_by!(username: params[:user_id])
                     end
        
        # Check if personal chat already exists between these users
        existing_chat = find_existing_personal_chat(other_user)
        if existing_chat
          redirect_to existing_chat, notice: t("rooms.messages.chat_exists")
          return
        end
        
        # Set name for personal chat
        @room.name = "#{current_user.username}, #{other_user.username}"
      end
      
      @room.save!
      @room.room_participants.create!(user: current_user, role: :owner)

      # For personal chats, add the other user
      if @room.personal_chat? && params[:user_id].present?
        # Reuse the other_user variable from above
        other_user = if params[:user_id].to_i.to_s == params[:user_id].to_s
                       User.find(params[:user_id])
                     else
                       User.find_by!(username: params[:user_id])
                     end
        @room.room_participants.create!(user: other_user, role: :member)
      end
    end

    redirect_to @room, notice: t("rooms.messages.created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    redirect_to search_path, alert: t("common.user_not_found")
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

  def mark_messages_as_read
    # Mark all unread messages in this room as read
    unread_messages = @room.messages.where.not(user: current_user).unread_by(current_user)
    unread_messages.each do |message|
      message.mark_as_read_by(current_user)
    end
  end
  
  def find_existing_personal_chat(other_user)
    # Find personal chat that includes both current_user and other_user
    Room.room_type_personal_chat
        .joins(:room_participants)
        .where(room_participants: { user: [current_user, other_user] })
        .group('rooms.id')
        .having('COUNT(DISTINCT room_participants.user_id) = 2')
        .first
  end
end
