class Room < ApplicationRecord
  has_many :room_participants, dependent: :destroy
  has_many :users, through: :room_participants
  has_many :messages, dependent: :destroy

  enum :room_type, { personal_chat: 0, group: 1, channel: 2 }, prefix: :room_type
  enum :visibility, { private_room: 0, public_room: 1 }, prefix: true

  validates :name, presence: true, length: { maximum: 100 }
  validates :room_type, presence: true
  validates :visibility, presence: true

  scope :public_channels, -> { room_type_channel.visibility_public_room }
  scope :for_user, ->(user) { joins(:room_participants).where(room_participants: { user_id: user.id }) }

  def owner
    room_participants.find_by(role: :owner)&.user
  end

  def admins
    users.joins(:room_participants).where(room_participants: { role: [ :owner, :admin ] })
  end

  def participant?(user)
    room_participants.exists?(user: user)
  end

  def can_write?(user)
    return false unless participant?(user)
    return true if room_type_personal_chat? || room_type_group?

    # For channels, only admins and owner can write
    room_participants.exists?(user: user, role: [ :owner, :admin ])
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  def unread_count_for(user)
    participant = room_participants.find_by(user: user)
    return 0 unless participant&.last_read_at

    messages.where("created_at > ?", participant.last_read_at).count
  end

  # Convenience methods for checking room type
  def personal_chat?
    room_type_personal_chat?
  end

  def group?
    room_type_group?
  end

  def channel?
    room_type_channel?
  end
end
