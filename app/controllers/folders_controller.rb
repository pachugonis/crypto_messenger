class FoldersController < ApplicationController
  allow_unauthenticated_access only: [ :shared ]
  before_action :set_folder, only: [ :show, :edit, :update, :destroy, :new_share_link, :generate_share_link, :revoke_share_link ]
  before_action :authorize_folder_owner, only: [ :show, :edit, :update, :destroy, :new_share_link, :generate_share_link, :revoke_share_link ]

  def index
    @folders = current_user.folders.root_folders.order(:name)
  end

  def show
    @subfolders = @folder.subfolders.order(:name)
    @attachments = @folder.attachments.includes(file_attachment: :blob).order(created_at: :desc)
  end

  def new
    @folder = current_user.folders.build(parent_folder_id: params[:parent_id])
  end

  def create
    @folder = current_user.folders.build(folder_params)

    if @folder.save
      respond_to do |format|
        format.html { redirect_to @folder, notice: t("folders.messages.created") }
        format.turbo_stream do
          # Reload parent folder's subfolders if creating in a folder
          if @folder.parent_folder
            @parent_folder = @folder.parent_folder
            @subfolders = @parent_folder.subfolders.order(:name)
          else
            # Reload root folders if creating at root level
            @folders = current_user.folders.root_folders.order(:name)
          end
        end
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @folder.update(folder_params)
      respond_to do |format|
        format.html { redirect_to @folder, notice: t("folders.messages.updated") }
        format.turbo_stream do
          # Reload parent folder's subfolders if this is a subfolder
          if @folder.parent_folder
            @parent_folder = @folder.parent_folder
            @subfolders = @parent_folder.subfolders.order(:name)
          else
            # Reload root folders if this is a root folder
            @folders = current_user.folders.root_folders.order(:name)
          end
        end
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    parent = @folder.parent_folder
    @folder.destroy
    redirect_to parent || folders_path, notice: t("folders.messages.deleted")
  end

  def generate_share_link
    expires_in = params[:expires_in]&.to_i || 7
    @token = @folder.generate_share_link!(expires_in: expires_in.days)

    respond_to do |format|
      format.turbo_stream do
        render :share_link_success
      end
      format.json { render json: { url: shared_folder_url(@token) } }
    end
  end

  def new_share_link
    render :new_share_link
  end

  def revoke_share_link
    @folder.revoke_share_link!
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "folder_share_link",
          partial: "folders/share_link",
          locals: { folder: @folder, token: nil }
        )
      end
      format.json { head :ok }
    end
  end

  def shared
    @folder = Folder.find_by(share_token: params[:token])

    if @folder.nil? || !@folder.share_token_valid?
      render :invalid_token, layout: "public", status: :not_found
      return
    end

    @subfolders = @folder.subfolders.order(:name)
    @attachments = @folder.attachments.includes(file_attachment: :blob).order(created_at: :desc)
    render :shared, layout: "public"
  end

  private

  def set_folder
    @folder = Folder.find(params[:id])
  end

  def authorize_folder_owner
    unless @folder.user == current_user
      redirect_to folders_path, alert: t("common.access_denied")
    end
  end

  def folder_params
    params.require(:folder).permit(:name, :parent_folder_id)
  end
end
