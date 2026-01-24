class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :room_participants, dependent: :destroy
  has_many :rooms, through: :room_participants
  has_many :messages, dependent: :destroy
  has_many :folders, dependent: :destroy
  has_many :attachments, dependent: :destroy

  has_one_attached :avatar

  enum :role, { user: 0, admin: 1 }

  normalizes :email_address, with: ->(e) { e.strip.downcase if e.present? }
  normalizes :username, with: ->(u) { u.strip.downcase }

  validates :email_address, uniqueness: true, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 30 },
                       format: { with: /\A[a-z0-9_]+\z/, message: :invalid_username_format }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }

  scope :active, -> { where(locked_at: nil) }
  scope :locked, -> { where.not(locked_at: nil) }

  # Generate recovery code on create
  before_create :generate_recovery_code

  def locked?
    locked_at.present?
  end

  def lock!
    update!(locked_at: Time.current)
  end

  def unlock!
    update!(locked_at: nil)
  end

  def display_name
    username
  end

  # Generate a new recovery code
  def generate_recovery_code
    # Generate 16 alphanumeric characters
    code_without_dashes = SecureRandom.alphanumeric(16).upcase
    
    # Store the code WITHOUT dashes in the digest
    self.recovery_code_digest = BCrypt::Password.create(code_without_dashes)
    
    # But show the code WITH dashes to the user for readability
    @recovery_code = code_without_dashes.scan(/.{4}/).join("-")
  end

  # Get the plain recovery code (only available once after generation)
  def recovery_code
    @recovery_code
  end

  # Verify recovery code
  def valid_recovery_code?(code)
    return false if recovery_code_digest.blank?
    return false if code.blank?
    
    # Clean the input code: remove all non-alphanumeric characters and convert to uppercase
    clean_code = code.to_s.gsub(/[^a-zA-Z0-9]/, '').upcase
    
    # Compare with stored digest
    BCrypt::Password.new(recovery_code_digest) == clean_code
  end

  # Regenerate recovery code
  def regenerate_recovery_code!
    generate_recovery_code
    save!
    @recovery_code
  end

  # Two-factor authentication methods
  def otp_provisioning_uri(issuer = "CryptoMessenger")
    return nil unless otp_secret
    
    ROTP::TOTP.new(otp_secret, issuer: issuer).provisioning_uri(username)
  end

  def validate_otp(code)
    Rails.logger.info "[OTP Validation] Start"
    Rails.logger.info "[OTP Validation] OTP Secret present: #{otp_secret.present?}"
    Rails.logger.info "[OTP Validation] Code: #{code.inspect}"
    
    return false unless otp_secret
    return false if code.blank?
    
    totp = ROTP::TOTP.new(otp_secret)
    clean_code = code.to_s.gsub(/\s+/, "")
    Rails.logger.info "[OTP Validation] Clean code: #{clean_code}"
    Rails.logger.info "[OTP Validation] Current TOTP: #{totp.now}"
    Rails.logger.info "[OTP Validation] Current time: #{Time.now.to_i}"
    
    # Allow 30 seconds drift in either direction
    result = totp.verify(clean_code, drift_behind: 30, drift_ahead: 30)
    Rails.logger.info "[OTP Validation] Result: #{result.inspect}"
    
    result ? true : false
  end

  def validate_backup_code(code)
    return false unless otp_enabled? && otp_backup_codes.present?
    return false if code.blank?
    
    codes = JSON.parse(otp_backup_codes)
    clean_code = code.to_s.gsub(/[^a-zA-Z0-9]/, '').downcase
    
    if codes.include?(clean_code)
      codes.delete(clean_code)
      update!(otp_backup_codes: codes.to_json)
      true
    else
      false
    end
  end

  def enable_otp!
    self.otp_secret = ROTP::Base32.random
    self.otp_backup_codes = generate_backup_codes.to_json
    self.otp_enabled = false # Will be enabled after verification
    save!
  end

  def disable_otp!
    self.otp_secret = nil
    self.otp_enabled = false
    self.otp_backup_codes = nil
    save!
  end

  def confirm_otp_setup!
    update!(otp_enabled: true)
  end

  def regenerate_backup_codes!
    return false unless otp_enabled?
    
    self.otp_backup_codes = generate_backup_codes.to_json
    save!
    JSON.parse(otp_backup_codes)
  end

  private

  def generate_backup_codes
    # Generate 10 backup codes (8 characters each)
    10.times.map do
      SecureRandom.alphanumeric(8).downcase
    end
  end
end
