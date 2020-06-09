class Broadcast < ApplicationRecord
  VALID_BANNER_STYLES = %w[default brand success warning error].freeze
  resourcify

  has_many :notifications, as: :notifiable, inverse_of: :notifiable

  validates :title, uniqueness: { scope: :type_of }, presence: true
  validates :type_of, :processed_html, presence: true
  validates :type_of, inclusion: { in: %w[Announcement Welcome] }
  validates :banner_style, inclusion: { in: VALID_BANNER_STYLES }, allow_blank: true
  validate  :single_active_announcement_broadcast
  # validate :last_active

  scope :active, -> { where(active: true) }
  scope :announcement, -> { where(type_of: "Announcement") }
  scope :welcome, -> { where(type_of: "Welcome") }

  def get_inner_body(content)
    Nokogiri::HTML(content).at("body").inner_html
  end

  private

  def single_active_announcement_broadcast
    # Only add errors if we are trying to modify an announcement
    # broadcast while another announcement broadcast is already
    # active to ensure that only one can be active at a time.
    active_broadcasts = Broadcast.announcement.active
    first_broadcast = active_broadcasts.order(id: :asc).limit(1)
    return unless active &&
      type_of == "Announcement" &&
      ![nil, id].include?(first_broadcast.pick(:id))

    errors.add(:base, "You can only have one active announcement broadcast")
  end

  # def last_active
  #   return unless @broadcast.last_active_at != updated_at

  #   Broadcast.update(last_active_at: Time.zone.now)
  # end

  # def last_active
  #   # Displays a timestamp showing when the Broadcast was last set to "active"
  #   # active_broadcast = Broadcast.active
  #   # active_broadcasts.order("active DESC")
  #   Broadcast.update(last_active_at: Time.current)
  # end
end
