class AttachmentsController < ApplicationController
  allow_unauthenticated_access only: [ :shared ]
  before_action :set_folder, only: [ :create, :destroy, :generate_link ]
  before_action :set_attachment, only: [ :destroy, :generate_link ]
  before_action :authorize_folder_owner, only: [ :create, :destroy, :generate_link ]

  def create
    @uploaded_count = 0
    @failed_files = []
    @created_folders = {}
    
    # Get files array and filter out empty values
    files = if params[:files].present?
              params[:files].reject(&:blank?)
            elsif params[:file].present?
              [params[:file]]
            else
              []
            end
    
    files.each_with_index do |file, index|
      
      # Get the relative path from hidden fields if available
      relative_path = if params[:file_paths].present? && params[:file_paths][index].present?
                        params[:file_paths][index]
                      else
                        file.original_filename
                      end
      
      # Extract folder structure from filename
      path_parts = relative_path.split('/')
      
      if path_parts.length > 1
        # File is inside a folder structure
        # First part is the root folder name that user uploaded
        root_folder_name = path_parts[0]
        folder_names = path_parts[0..-2] # All parts except filename
        filename = path_parts.last
        
        # Create or find the root uploaded folder
        root_cache_key = "#{@folder.id}_#{root_folder_name}"
        if @created_folders[root_cache_key]
          current_folder = @created_folders[root_cache_key]
        else
          root_folder = @folder.subfolders.find_by(name: root_folder_name)
          unless root_folder
            root_folder = @folder.subfolders.create!(
              name: root_folder_name,
              user: current_user
            )
          end
          @created_folders[root_cache_key] = root_folder
          current_folder = root_folder
        end
        
        # Create nested folder structure if there are more levels
        if folder_names.length > 1
          folder_names[1..-1].each do |folder_name|
            cache_key = "#{current_folder.id}_#{folder_name}"
            
            if @created_folders[cache_key]
              current_folder = @created_folders[cache_key]
            else
              # Find or create subfolder
              subfolder = current_folder.subfolders.find_by(name: folder_name)
              unless subfolder
                subfolder = current_folder.subfolders.create!(
                  name: folder_name,
                  user: current_user
                )
              end
              @created_folders[cache_key] = subfolder
              current_folder = subfolder
            end
          end
        end
        
        # Upload file to the deepest folder
        @attachment = current_folder.attachments.build(user: current_user)
      else
        # Regular file upload to current folder
        @attachment = @folder.attachments.build(user: current_user)
      end
      
      @attachment.file.attach(file)
      
      if @attachment.save
        @uploaded_count += 1
      else
        @failed_files << file.original_filename
      end
    end

    if @uploaded_count > 0
      # Reload folder to get updated attachments and subfolders
      @folder.reload
      @subfolders = @folder.subfolders.order(:name)
      @attachments = @folder.attachments.order(created_at: :desc)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("subfolders-section", partial: "folders/subfolders", locals: { subfolders: @subfolders }),
            turbo_stream.replace("attachments", partial: "folders/attachments", locals: { attachments: @attachments })
          ]
        end
        format.html { redirect_to @folder, notice: t("attachments.messages.uploaded_multiple", count: @uploaded_count) }
      end
    else
      redirect_to @folder, alert: t("attachments.messages.upload_failed", files: @failed_files.join(', '))
    end
  end

  def destroy
    @attachment.destroy
    # Reload folder for turbo_stream response
    @folder.reload
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
