class TwoFactorAuthenticationController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]
  before_action :set_user_from_session, only: [ :new, :create ]

  def new
    # Show 2FA code input page
    redirect_to root_path unless session[:pending_2fa_user_id]
  end

  def create
    if @user.validate_otp(params[:otp_code])
      complete_authentication
    elsif @user.validate_backup_code(params[:otp_code])
      complete_authentication
      flash[:alert] = t("two_factor.messages.backup_code_used")
    else
      redirect_to two_factor_authentication_path, alert: t("two_factor.messages.invalid_code")
    end
  end

  private

  def set_user_from_session
    @user = User.find_by(id: session[:pending_2fa_user_id])
    redirect_to new_session_path unless @user
  end

  def complete_authentication
    session.delete(:pending_2fa_user_id)
    start_new_session_for @user
    redirect_to after_authentication_url, notice: t("auth.messages.signed_in")
  end
end
