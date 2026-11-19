# Groups billboards that share an end date and delivery caps. Billboards in a
# campaign are taken down once the campaign expires or the campaign's billboards
# together reach either cap. A cap of 0 means no cap.
class BillboardCampaign < ApplicationRecord
  belongs_to :organization, optional: true
  has_many :billboards, dependent: :nullify

  validates :name, presence: true
  validates :max_impressions_count, :max_clicks_count, numericality: { greater_than_or_equal_to: 0 }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def over_cap?
    cap_reached?(max_impressions_count, :impressions_count) || cap_reached?(max_clicks_count, :clicks_count)
  end

  private

  def cap_reached?(cap, column)
    cap.positive? && billboards.sum(column) >= cap
  end
end
