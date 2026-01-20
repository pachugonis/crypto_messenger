class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true
  belongs_to :user

  has_one_attached :file

  validates :file, presence: true

  before_create :generate_access_token

  scope :with_valid_token, -> { where("access_token_expires_at IS NULL OR access_token_expires_at > ?", Time.current) }

  def token_valid?
    access_token_expires_at.nil? || access_token_expires_at > Time.current
  end

  def generate_share_link!(expires_in: 7.days)
    update!(
      access_token: SecureRandom.urlsafe_base64(32),
      access_token_expires_at: Time.current + expires_in
    )
    access_token
  end

  def revoke_share_link!
    update!(access_token: nil, access_token_expires_at: nil)
  end

  def filename
    file.filename.to_s
  end

  def content_type
    file.content_type
  end

  def byte_size
    file.byte_size
  end

  def image?
    file.content_type&.start_with?("image/")
  end

  private

  def generate_access_token
    self.access_token ||= SecureRandom.urlsafe_base64(32)
  end
end
