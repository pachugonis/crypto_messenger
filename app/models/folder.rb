class Folder < ApplicationRecord
  belongs_to :user
  belongs_to :parent_folder, class_name: "Folder", optional: true
  has_many :subfolders, class_name: "Folder", foreign_key: :parent_folder_id, dependent: :destroy
  has_many :attachments, as: :attachable, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: [ :user_id, :parent_folder_id ] }

  scope :root_folders, -> { where(parent_folder_id: nil) }
  scope :for_user, ->(user) { where(user: user)}

  def path
    parent_folder ? "#{parent_folder.path}/#{name}" : name
  end

  def ancestors
    folder = self
    result = []
    while folder.parent_folder
      result.unshift(folder.parent_folder)
      folder = folder.parent_folder
    end
    result
  end

  # Generate share link
  def generate_share_link!(expires_in: 7.days)
    token = SecureRandom.urlsafe_base64(32)
    update!(
      share_token: token,
      share_expires_at: expires_in.from_now
    )
    token
  end

  # Check if share token is valid
  def share_token_valid?
    share_token.present? && (share_expires_at.nil? || share_expires_at > Time.current)
  end

  # Revoke share link
  def revoke_share_link!
    update!(share_token: nil, share_expires_at: nil)
  end
end
