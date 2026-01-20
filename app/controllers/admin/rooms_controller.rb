class Admin::RoomsController < Admin::BaseController
  before_action :set_room, only: [ :show, :destroy ]

  def index
    @rooms = Room.includes(:users).order(created_at: :desc)

    if params[:type].present?
      @rooms = @rooms.where(room_type: params[:type])
    end

    if params[:q].present?
      @rooms = @rooms.where("name ILIKE ?", "%#{params[:q]}%")
    end

    @rooms = @rooms.page(params[:page]).per(20) if @rooms.respond_to?(:page)
  end

  def show
    @participants = @room.room_participants.includes(:user)
    @messages_count = @room.messages.count
  end

  def destroy
    @room.destroy
    redirect_to admin_rooms_path, notice: t("admin.rooms.deleted")
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end
end
