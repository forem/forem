class Broadcast < ApplicationRecord
  ALLOWED_TYPES = %w[Announcement WelcomeNotification].freeze
  resourcify

  belongs_to :broadcastable, polymorphic: true
  belongs_to :announcement, class_name: "Announcement", optional: true
  belongs_to :welcome_notification, class_name: "WelcomeNotification", optional: true

  validates :title, uniqueness: { scope: :broadcastable_type }, presence: true
  validates :processed_html, :broadcastable_type, :broadcastable_id, presence: true
  validates :broadcastable_type, inclusion: { in: ALLOWED_TYPES }
  validate  :single_active_announcement_broadcast

  before_save :update_active_status_updated_at, if: :will_save_change_to_active?

  scope :active, -> { where(active: true) }
  scope :announcement, -> { where(broadcastable_type: "Announcement") }
  scope :welcome_notification, -> { where(broadcastable_type: "WelcomeNotification") }

  def get_inner_body(content)
    Nokogiri::HTML(content).at("body").inner_html
  end

  private

  def single_active_announcement_broadcast
    # TODO: [@thepracticaldev/delightful]: Move this logic into the Announcement model

    # Only add errors if we are trying to modify an announcement
    # broadcast while another announcement broadcast is already
    # active to ensure that only one can be active at a time.
    active_broadcasts = Broadcast.announcement.active
    first_broadcast = active_broadcasts.order(id: :asc).limit(1)
    return unless active &&
      broadcastable_type == "Announcement" &&
      ![nil, id].include?(first_broadcast.pick(:id))

    errors.add(:base, "You can only have one active announcement broadcast")
  end

  def update_active_status_updated_at
    self.active_status_updated_at = Time.current
  end
end
