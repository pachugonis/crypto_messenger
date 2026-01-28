class RoomsController < ApplicationController
  before_action :set_room, only: [ :show, :edit, :update, :destroy, :leave, :join, :mark_read, :destroy_image ]
  before_action :authorize_room_access, only: [ :show ]
  before_action :authorize_room_edit, only: [ :edit, :update, :destroy_image ]
  before_action :authorize_room_delete, only: [ :destroy ]
  before_action :authorize_public_room_or_participant, only: [ :join ]

  def index
    @rooms = current_user.rooms.includes(:users, :messages).order(updated_at: :desc)
    @personal_chats = @rooms.select(&:personal_chat?)
    @groups = @rooms.select(&:group?)
    @channels = @rooms.select(&:channel?)
  end

  def show
    # Allow viewing public rooms even if not a participant
    @is_participant = @room.participant?(current_user)
    
    if @is_participant
      @messages = @room.messages.not_deleted.chronological.includes(:user, :message_reads).last(50)
      @participant = @room.room_participants.find_by(user: current_user)
      @participant&.mark_as_read!
      
      # Mark all messages in this room as read by current user
      mark_messages_as_read
    else
      # For non-participants, show empty messages or limited info
      @messages = []
    end
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

      # Process and attach image if provided
      if params[:room] && params[:room][:image].present?
        require 'mini_magick'
        
        file = params[:room][:image]
        image = MiniMagick::Image.read(file.tempfile)
        
        # Crop to square from center
        size = [image.width, image.height].min
        image.crop "#{size}x#{size}+#{(image.width - size) / 2}+#{(image.height - size) / 2}"
        # Resize to 200x200
        image.resize "200x200"
        
        # Attach processed image
        @room.image.attach(
          io: File.open(image.path),
          filename: "room_#{@room.id}.jpg",
          content_type: "image/jpeg"
        )
      end

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

    respond_to do |format|
      format.html do
        # Don't show "Chat created" notice for personal chats, just open the chat
        if @room.personal_chat?
          redirect_to @room
        else
          redirect_to @room, notice: t("rooms.messages.created")
        end
      end
      format.turbo_stream do
        # Update sidebar with new room and redirect to room
        @rooms = current_user.rooms.includes(:users, :messages).order(updated_at: :desc)
      end
    end
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    redirect_to search_path, alert: t("common.user_not_found")
  end

  def edit
  end

  def update
    if params[:room] && params[:room][:image].present?
      # Process the image with ImageProcessing
      require 'mini_magick'
      
      file = params[:room][:image]
      image = MiniMagick::Image.read(file.tempfile)
      
      # Crop to square from center
      size = [image.width, image.height].min
      image.crop "#{size}x#{size}+#{(image.width - size) / 2}+#{(image.height - size) / 2}"
      # Resize to 200x200
      image.resize "200x200"
      
      # Attach processed image
      @room.image.attach(
        io: File.open(image.path),
        filename: "room_#{@room.id}.jpg",
        content_type: "image/jpeg"
      )
    end

    if params[:room].present? && @room.update(room_params)
      redirect_to @room, notice: t("rooms.messages.updated")
    elsif params[:room].blank?
      # If no room params (e.g., from image deletion), just redirect
      redirect_to edit_room_path(@room)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @room.destroy
    
    respond_to do |format|
      format.turbo_stream do
        # Return updated rooms list for sidebar
        @rooms = current_user.rooms.includes(:users, :messages).order(updated_at: :desc)
      end
      format.html { redirect_to rooms_path, notice: t("rooms.messages.deleted") }
    end
  end

  def leave
    participant = @room.room_participants.find_by(user: current_user)
    participant&.destroy
    redirect_to rooms_path, notice: t("rooms.messages.left")
  end

  def join
    unless @room.participant?(current_user)
      @room.room_participants.create!(user: current_user, role: :member)
      redirect_to @room, notice: t("rooms.messages.joined")
    else
      redirect_to @room, alert: t("rooms.messages.already_member")
    end
  end

  def mark_read
    participant = @room.room_participants.find_by(user: current_user)
    participant&.mark_as_read!
    head :ok
  end

  def destroy_image
    if @room.image.attached?
      @room.image.purge
      Rails.logger.info "Image purged for room #{@room.id}"
      redirect_to edit_room_path(@room), notice: t("rooms.messages.image_removed")
    else
      Rails.logger.warn "Attempted to delete non-existent image for room #{@room.id}"
      redirect_to edit_room_path(@room), alert: "Image not found"
    end
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

  def authorize_room_edit
    # For personal chats, both participants can edit
    if @room.personal_chat?
      unless @room.participant?(current_user)
        redirect_to rooms_path, alert: t("common.access_denied")
      end
    else
      # For groups and channels, only owner and admins can edit
      participant = @room.room_participants.find_by(user: current_user)
      unless participant && (participant.owner? || participant.admin?)
        redirect_to rooms_path, alert: t("common.access_denied")
      end
    end
  end

  def authorize_room_delete
    # Only owner and admin can delete room
    if @room.personal_chat?
      unless @room.participant?(current_user)
        redirect_to rooms_path, alert: t("common.access_denied")
      end
    else
      # For groups and channels, owner and admins can delete
      participant = @room.room_participants.find_by(user: current_user)
      unless participant && (participant.owner? || participant.admin?)
        redirect_to rooms_path, alert: t("common.access_denied")
      end
    end
  end
  
  def authorize_public_room_or_participant
    # Allow access to join action only for public rooms
    unless @room.visibility_public_room?
      redirect_to rooms_path, alert: t("common.access_denied")
    end
  end

  def room_params
    params.require(:room).permit(:name, :description, :room_type, :visibility, :handle)
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
