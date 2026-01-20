class FoldersController < ApplicationController
  before_action :set_folder, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_folder_owner, only: [ :show, :edit, :update, :destroy ]

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
      redirect_to @folder, notice: t("folders.messages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @folder.update(folder_params)
      redirect_to @folder, notice: t("folders.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    parent = @folder.parent_folder
    @folder.destroy
    redirect_to parent || folders_path, notice: t("folders.messages.deleted")
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
