class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    if @query.present?
      @users = User.where("username ILIKE ? OR email_address ILIKE ?", "%#{@query}%", "%#{@query}%")
                   .where.not(id: current_user.id)
                   .limit(10)

      @rooms = Room.for_user(current_user)
                   .where("name ILIKE ?", "%#{@query}%")
                   .limit(10)

      @public_channels = Room.channel
                             .visibility_public_room
                             .where("name ILIKE ?", "%#{@query}%")
                             .where.not(id: current_user.rooms.pluck(:id))
                             .limit(10)
    else
      @users = []
      @rooms = []
      @public_channels = []
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
