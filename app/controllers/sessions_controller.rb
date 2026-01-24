class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    Rails.logger.info "[Login] Username: #{params[:username]}"
    
    if user = User.find_by(username: params[:username]&.strip&.downcase)&.authenticate(params[:password])
      Rails.logger.info "[Login] User found: #{user.id}, locked: #{user.locked?}, otp_enabled: #{user.otp_enabled}"
      
      if user.locked?
        redirect_to new_session_path, alert: t("auth.messages.account_locked")
      elsif user.otp_enabled?
        # Store user ID in session for 2FA verification
        session[:pending_2fa_user_id] = user.id
        Rails.logger.info "[Login] Redirecting to 2FA, session[:pending_2fa_user_id] = #{session[:pending_2fa_user_id]}"
        redirect_to new_two_factor_authentication_path
      else
        start_new_session_for user
        redirect_to after_authentication_url
      end
    else
      Rails.logger.warn "[Login] Authentication failed for username: #{params[:username]}"
      redirect_to new_session_path, alert: t("auth.messages.invalid_credentials")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
