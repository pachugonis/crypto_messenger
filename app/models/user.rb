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
    @recovery_code = SecureRandom.alphanumeric(16).upcase.scan(/.{4}/).join("-")
    self.recovery_code_digest = BCrypt::Password.create(@recovery_code)
  end

  # Get the plain recovery code (only available once after generation)
  def recovery_code
    @recovery_code
  end

  # Verify recovery code
  def valid_recovery_code?(code)
    return false if recovery_code_digest.blank?
    BCrypt::Password.new(recovery_code_digest) == code.gsub("-", "").upcase
  end

  # Regenerate recovery code
  def regenerate_recovery_code!
    generate_recovery_code
    save!
    @recovery_code
  end
end
