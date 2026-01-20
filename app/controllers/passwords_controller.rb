class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_recovery_code, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  def create
    username = params[:username]&.strip&.downcase
    recovery_code = params[:recovery_code]&.strip

    @user = User.find_by(username: username)
    
    if @user.nil?
      Rails.logger.info "Password recovery failed: User not found with username '#{username}'"
      redirect_to new_password_path, alert: t("auth.recovery.invalid")
    elsif @user.valid_recovery_code?(recovery_code)
      Rails.logger.info "Password recovery successful for user '#{username}'"
      redirect_to edit_password_path(token: encode_token(@user.id))
    else
      Rails.logger.info "Password recovery failed: Invalid recovery code for user '#{username}'"
      redirect_to new_password_path, alert: t("auth.recovery.invalid")
    end
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      # Regenerate recovery code after password reset
      new_recovery_code = @user.regenerate_recovery_code!
      flash[:notice] = t("auth.recovery.password_reset")
      flash[:recovery_code] = new_recovery_code
      redirect_to new_session_path
    else
      redirect_to edit_password_path(params[:token]), alert: t("auth.recovery.passwords_no_match")
    end
  end

  private
    def set_user_by_recovery_code
      user_id = decode_token(params[:token])
      @user = User.find(user_id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
      redirect_to new_password_path, alert: t("auth.recovery.invalid_link")
    end

    def encode_token(user_id)
      Rails.application.message_verifier(:password_reset).generate(user_id, expires_in: 1.hour)
    end

    def decode_token(token)
      Rails.application.message_verifier(:password_reset).verify(token)
    end
end
