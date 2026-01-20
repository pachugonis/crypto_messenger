class RoomParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :room, counter_cache: :participants_count

  enum :role, { member: 0, admin: 1, owner: 2 }

  validates :user_id, uniqueness: { scope: :room_id }
  validates :role, presence: true

  scope :admins, -> { where(role: [ :admin, :owner ]) }

  def mark_as_read!
    update!(last_read_at: Time.current)
  end

  def toggle_mute!
    update!(muted: !muted)
  end
end
