class MessageRead < ApplicationRecord
  belongs_to :message
  belongs_to :user

  validates :message_id, uniqueness: { scope: :user_id }
  validates :read_at, presence: true

  before_validation :set_read_at, on: :create

  private

  def set_read_at
    self.read_at ||= Time.current
  end
end
