class Reaction < ApplicationRecord
  belongs_to :message
  belongs_to :user
  
  validates :emoji, presence: true
  validates :user_id, uniqueness: { scope: :message_id, message: "пользователь может поставить только одну реакцию к посту" }
  
  # Popular emoji list
  EMOJI_LIST = %w[👍 ❤️ 😂 😮 😢 🎉 🔥 👏 ✅ ⭐].freeze
end
