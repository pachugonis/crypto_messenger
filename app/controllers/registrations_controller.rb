class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      recovery_code = @user.recovery_code
      start_new_session_for @user
      redirect_to show_recovery_code_path(recovery_code: recovery_code), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show_recovery_code
    @recovery_code = params[:recovery_code]
  end

  private

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation)
  end
end
