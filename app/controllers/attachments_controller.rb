class AttachmentsController < ApplicationController
  allow_unauthenticated_access only: [ :shared ]
  before_action :set_folder, only: [ :create, :destroy, :generate_link ]
  before_action :set_attachment, only: [ :destroy, :generate_link ]
  before_action :authorize_folder_owner, only: [ :create, :destroy, :generate_link ]

  def create
    @attachment = @folder.attachments.build(user: current_user)
    @attachment.file.attach(params[:file])

    if @attachment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @folder, notice: t("attachments.messages.uploaded") }
      end
    else
      redirect_to @folder, alert: @attachment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @attachment.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @folder, notice: t("attachments.messages.deleted") }
    end
  end

  def generate_link
    expires_in = params[:expires_in]&.to_i || 7
    token = @attachment.generate_share_link!(expires_in: expires_in.days)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "share_link_#{@attachment.id}",
          partial: "attachments/share_link",
          locals: { attachment: @attachment, token: token }
        )
      end
      format.json { render json: { url: shared_attachment_url(token) } }
    end
  end

  def shared
    @attachment = Attachment.find_by(access_token: params[:token])

    if @attachment.nil? || !@attachment.token_valid?
      render :invalid_token, status: :not_found
      return
    end

    redirect_to rails_blob_path(@attachment.file, disposition: "attachment"), allow_other_host: true
  end

  private

  def set_folder
    @folder = Folder.find(params[:folder_id])
  end

  def set_attachment
    @attachment = @folder.attachments.find(params[:id])
  end

  def authorize_folder_owner
    unless @folder.user == current_user
      redirect_to folders_path, alert: t("common.access_denied")
    end
  end
end
