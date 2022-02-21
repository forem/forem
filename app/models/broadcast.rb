class Broadcast < ApplicationRecord
  VALID_BANNER_STYLES = %w[default brand success warning error].freeze
  resourcify

  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :destroy

  validates :title, uniqueness: { scope: :type_of }, presence: true
  validates :type_of, :processed_html, presence: true
  validates :type_of, inclusion: { in: %w[Announcement Welcome] }
  validates :banner_style, inclusion: { in: VALID_BANNER_STYLES }, allow_blank: true
  validate  :single_active_announcement_broadcast

  before_save :update_active_status_updated_at, if: :will_save_change_to_active?

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
      [nil, id].exclude?(first_broadcast.pick(:id))

    errors.add(:base, I18n.t("models.broadcast.single_active"))
  end

  def update_active_status_updated_at
    self.active_status_updated_at = Time.current
  end
end
