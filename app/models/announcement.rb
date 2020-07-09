class Announcement < ApplicationRecord
  VALID_BANNER_STYLES = %w[default brand success warning error].freeze
  resourcify

  has_one :broadcast, as: :broadcastable

  validates :banner_style, inclusion: { in: VALID_BANNER_STYLES }, allow_blank: true
  validate  :single_active_announcement_broadcast

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
end
