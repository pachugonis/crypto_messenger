class ProfilesController < ApplicationController
  before_action :set_user

  def show
  end

  def edit
  end

  def update
    # Handle cropped avatar
    if params[:cropped_avatar].present? && params[:cropped_avatar] != ""
      decoded_image = decode_base64_image(params[:cropped_avatar])
      @user.avatar.attach(
        io: StringIO.new(decoded_image),
        filename: "avatar_#{@user.id}.jpg",
        content_type: "image/jpeg"
      )
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to profile_path, notice: t("profile.messages.avatar_updated") }
      end
      return
    end

    # Handle regular file upload if no cropped version
    if params[:user] && params[:user][:avatar].present?
      @user.avatar.attach(params[:user][:avatar])
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to profile_path, notice: t("profile.messages.avatar_updated") }
      end
      return
    end

    if user_params[:password].present?
      if @user.update(user_params)
        flash[:notice] = t("profile.messages.password_updated")
        # Generate new recovery code
        @new_recovery_code = @user.regenerate_recovery_code!
        render :show_recovery_code
      else
        render :edit, status: :unprocessable_entity
      end
    elsif @user.update(user_params.except(:password, :password_confirmation))
      redirect_to profile_path, notice: t("profile.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy_avatar
    @user.avatar.purge
    respond_to do |format|
      format.turbo_stream { render :update }
      format.html { redirect_to profile_path, notice: t("profile.messages.avatar_removed") }
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def decode_base64_image(base64_string)
    # Remove data:image/...;base64, prefix
    encoded_image = base64_string.split(',')[1]
    Base64.decode64(encoded_image)
  end
end
