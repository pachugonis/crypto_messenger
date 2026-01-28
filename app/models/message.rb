class Message < ApplicationRecord
  belongs_to :room, counter_cache: :messages_count
  belongs_to :user
  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :message_reads, dependent: :destroy
  has_many :readers, through: :message_reads, source: :user
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_one_attached :image

  encrypts :content

  enum :message_type, { text: 0, system: 1 }
  enum :status, { sending: 0, sent: 1, delivered: 2, read: 3, failed: 4 }

  validates :content, presence: true, unless: -> { has_attachments? || deleted? || image.attached? }
  validates :image, content_type: [:png, :jpg, :jpeg, :gif, :webp],
                   size: { less_than: 1.megabytes, message: "должно быть меньше 1 МБ" }

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :unread_by, ->(user) { where.not(id: MessageRead.where(user: user).select(:message_id)) }

  after_create_commit :broadcast_message, :mark_as_sent
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

  # Mark message as read by user
  def mark_as_read_by(user)
    return if user == self.user # Don't mark own messages as read
    
    message_reads.find_or_create_by(user: user) do |read|
      read.read_at = Time.current
    end
    
    # Update message status to read if all participants have read it
    update_status_based_on_reads
  end

  # Mark message as delivered
  def mark_as_delivered
    return if delivered? || read?
    update_columns(status: Message.statuses[:delivered], delivered_at: Time.current)
    broadcast_update
  end

  # Check if message is read by specific user
  def read_by?(user)
    message_reads.exists?(user: user)
  end

  # Get read status for room
  def read_count
    message_reads.count
  end

  # Get unread participants count
  def unread_count
    room.participants_count - read_count - 1 # -1 for sender
  end
  
  # Check if comments are allowed (only in channels)
  def comments_allowed?
    room.channel?
  end
  
  # Get comments count
  def comments_count
    comments.not_deleted.count
  end
  
  # Check if reactions are allowed (groups and channels)
  def reactions_allowed?
    room.group? || room.channel?
  end
  
  # Get grouped reactions
  def grouped_reactions
    reactions.group(:emoji).count
  end
  
  # Check if user reacted with specific emoji
  def user_reacted?(user, emoji)
    reactions.exists?(user: user, emoji: emoji)
  end
  
  # Get user's reaction to this message (if any)
  def user_reaction(user)
    reactions.find_by(user: user)
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

  # Mark message as sent after creation
  def mark_as_sent
    update_column(:status, :sent) if sending?
  end

  # Update status based on reads
  def update_status_based_on_reads
    return if read?
    
    # Check if all other participants have read the message
    other_participants = room.room_participants.where.not(user: user)
    return if other_participants.empty?
    
    all_read = other_participants.all? do |participant|
      message_reads.exists?(user: participant.user)
    end
    
    if all_read
      update_column(:status, Message.statuses[:read])
      broadcast_update
    end
  end
end
