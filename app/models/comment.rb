class Comment < ApplicationRecord
  belongs_to :message
  belongs_to :user
  
  validates :content, presence: true, length: { maximum: 10000 }
  
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :chronological, -> { order(created_at: :asc) }
  
  def deleted?
    deleted_at.present?
  end
  
  def soft_delete
    update(deleted_at: Time.current)
  end
end
