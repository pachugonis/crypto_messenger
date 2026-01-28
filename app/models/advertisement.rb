class Advertisement < ApplicationRecord
  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }
  
  # Icon types: svg, image, emoji
  ICON_TYPES = %w[svg image emoji].freeze
  
  # Icon colors for SVG
  ICON_COLORS = {
    'primary' => 'text-primary',
    'secondary' => 'text-secondary',
    'accent' => 'text-accent',
    'success' => 'text-success',
    'warning' => 'text-warning',
    'error' => 'text-error'
  }.freeze
  
  validates :icon_type, inclusion: { in: ICON_TYPES }, allow_blank: true
  
  def icon_color_class
    ICON_COLORS[icon_color] || 'text-primary'
  end
end
