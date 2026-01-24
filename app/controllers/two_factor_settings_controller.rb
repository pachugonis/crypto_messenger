class TwoFactorSettingsController < ApplicationController
  before_action :set_user

  def show
    # Show 2FA settings page
  end

  def enable
    @user.enable_otp!
    Rails.logger.info "[2FA Enable] User: #{@user.id}"
    Rails.logger.info "[2FA Enable] OTP Secret: #{@user.otp_secret}"
    Rails.logger.info "[2FA Enable] OTP URI: #{@user.otp_provisioning_uri}"
    @qr_code = generate_qr_code(@user.otp_provisioning_uri)
    @backup_codes = JSON.parse(@user.otp_backup_codes)
  end

  def verify
    Rails.logger.info "=== 2FA Verify Start ==="
    Rails.logger.info "User ID: #{@user.id}"
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "OTP Code param: #{params[:otp_code].inspect}"
    Rails.logger.info "User OTP Secret present: #{@user.otp_secret.present?}"
    Rails.logger.info "User OTP Enabled: #{@user.otp_enabled}"
    
    validation_result = @user.validate_otp(params[:otp_code])
    Rails.logger.info "Validation result: #{validation_result}"
    
    if validation_result
      @user.confirm_otp_setup!
      Rails.logger.info "2FA enabled successfully for user #{@user.id}"
      flash[:notice] = t("two_factor.messages.enabled")
      redirect_to two_factor_settings_path, status: :see_other
    else
      Rails.logger.warn "2FA verification failed for user #{@user.id}"
      @qr_code = generate_qr_code(@user.otp_provisioning_uri)
      @backup_codes = JSON.parse(@user.otp_backup_codes)
      flash.now[:alert] = t("two_factor.messages.invalid_code")
      render :enable, status: :unprocessable_entity
    end
  end

  def disable
    Rails.logger.info "[2FA Disable] User: #{@user.id}"
    Rails.logger.info "[2FA Disable] Username: #{@user.username}"
    Rails.logger.info "[2FA Disable] Password present: #{params[:password].present?}"
    Rails.logger.info "[2FA Disable] Password length: #{params[:password]&.length}"
    
    auth_result = @user.authenticate(params[:password])
    Rails.logger.info "[2FA Disable] Authentication result: #{auth_result.inspect}"
    
    if auth_result
      Rails.logger.info "[2FA Disable] Password correct, disabling 2FA"
      @user.disable_otp!
      flash.now[:notice] = t("two_factor.messages.disabled")
      render :show
    else
      Rails.logger.warn "[2FA Disable] Invalid password for user #{@user.username}"
      flash.now[:alert] = t("auth.messages.invalid_credentials")
      render :show, status: :unprocessable_entity
    end
  end

  def regenerate_codes
    if @user.authenticate(params[:password])
      @backup_codes = @user.regenerate_backup_codes!
      render :show_backup_codes
    else
      @show_regenerate_form = true
      flash.now[:alert] = t("auth.messages.invalid_credentials")
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def generate_qr_code(uri)
    require 'rqrcode'
    qrcode = RQRCode::QRCode.new(uri)
    qrcode.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 4,
      standalone: true
    )
  end
end
