class Message < ApplicationRecord
  belongs_to :room, counter_cache: :messages_count
  belongs_to :user
  has_many :attachments, as: :attachable, dependent: :destroy

  encrypts :content

  enum :message_type, { text: 0, system: 1 }

  validates :content, presence: true, unless: -> { has_attachments? || deleted? }

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }

  after_create_commit :broadcast_message
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current, content: "")
  end

  def edited?
    updated_at > created_at + 1.second
  end

  private

  def has_attachments?
    attachments.any?
  end

  def broadcast_message
    broadcast_append_to room,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
  end

  def broadcast_update
    broadcast_replace_to room,
      target: self,
      partial: "messages/message",
      locals: { message: self }
  end

  def broadcast_destroy
    broadcast_remove_to room, target: self
  end
end
