class CommentsController < ApplicationController
  before_action :set_message
  before_action :set_comment, only: [:destroy]
  before_action :authorize_room_access
  before_action :authorize_comment_delete, only: [:destroy]

  def create
    @comment = @message.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to room_path(@message.room), notice: "Комментарий добавлен" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment-form-#{@message.id}", partial: "comments/form", locals: { message: @message, comment: @comment }) }
        format.html { redirect_to room_path(@message.room), alert: "Ошибка при добавлении комментария" }
      end
    end
  end

  def destroy
    @comment.soft_delete

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to room_path(@message.room), notice: "Комментарий удалён" }
    end
  end

  private

  def set_message
    @message = Message.find(params[:message_id])
  end

  def set_comment
    @comment = @message.comments.find(params[:id])
  end

  def authorize_room_access
    room = @message.room
    unless room.participant?(current_user)
      redirect_to rooms_path, alert: t("common.access_denied")
    end
  end

  def authorize_comment_delete
    unless @comment.user == current_user || @message.room.room_participants.find_by(user: current_user)&.owner? || @message.room.room_participants.find_by(user: current_user)&.admin?
      redirect_to room_path(@message.room), alert: t("common.access_denied")
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
