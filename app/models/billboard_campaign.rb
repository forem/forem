# Groups billboards that share an end date and delivery caps. Billboards in a
# campaign are taken down once the campaign expires or the campaign's billboards
# together reach either cap. A cap of 0 means no cap.
class BillboardCampaign < ApplicationRecord
  MAX_CAP = 2_147_483_647

  belongs_to :organization, optional: true
  has_many :billboards, dependent: :nullify

  validates :name, presence: true
  validates :max_impressions_count, :max_clicks_count, :ideal_daily_impressions,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_CAP }
  validates :delivery_throttle_rate,
            numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }

  scope :with_ideal_daily_impressions, -> { where("ideal_daily_impressions > 0") }

  before_save :reset_delivery_throttle_rate, if: :should_reset_delivery_throttle_rate?
  after_commit :clear_throttle_cache_if_disabled, on: %i[update destroy]

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  # Match billboard saves: lock the billboard rows before locking their campaign.
  def with_billboards_locked
    self.class.transaction do
      billboards.order(:id).lock.ids
      lock!
      yield
    end
  end

  # A billboard is live here when it is approved or Event-owned, the same rule BillboardPolicy uses.
  def governs_live_billboard?(except: nil)
    live = billboards.where(approved: true).or(billboards.where.not(event_id: nil))
    live = live.where.not(id: except.id) if except&.persisted?
    live.exists?
  end

  # Pass the billboard being saved to count its unsaved counts and membership exactly once.
  def over_cap?(billboard = nil)
    cap_reached?(max_impressions_count, :impressions_count, billboard) ||
      cap_reached?(max_clicks_count, :clicks_count, billboard)
  end

  private

  def cap_reached?(cap, column, billboard)
    return false unless cap.to_i.positive?

    others = billboard&.persisted? ? billboards.where.not(id: billboard.id) : billboards
    others.sum(column) + billboard&.public_send(column).to_i >= cap
  end

  def should_reset_delivery_throttle_rate?
    ideal_daily_impressions.to_i.zero? && delivery_throttle_rate.to_f < 1.0
  end

  def reset_delivery_throttle_rate
    self.delivery_throttle_rate = 1.0
  end

  def clear_throttle_cache_if_disabled
    return unless destroyed? || (saved_change_to_ideal_daily_impressions? && ideal_daily_impressions.to_i.zero?)

    Billboards::CampaignPacing.refresh_throttled_campaign_rates_cache!
  end
end
