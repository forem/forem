require "rails_helper"

RSpec.describe DisplayAdEventRollup, type: :service do
  let(:ad1) { create :display_ad }
  let(:ad2) { create :display_ad }
  let(:user1) { create :user }

  def override_timestamps
    DisplayAdEvent.record_timestamps = false
    yield
    DisplayAdEvent.record_timestamps = true
  end

  def days_ago_as_range(num)
    (Date.current - num.days).all_day
  end

  it "compacts display_ad_events" do
    override_timestamps do
      create(:display_ad_event, created_at: Date.current - 2, display_ad: ad1, user_id: nil, updated_at: Date.current)
      create(:display_ad_event, created_at: Date.current - 2, display_ad: ad1, user_id: nil, updated_at: Date.current)
      create(:display_ad_event, created_at: Date.current - 2, display_ad: ad1, user_id: nil, updated_at: Date.current)

      create(:display_ad_event, created_at: Date.current - 2, display_ad: ad1, user_id: user1.id,
                                updated_at: Date.current)
      create(:display_ad_event, created_at: Date.current - 2, display_ad: ad2, user_id: nil, updated_at: Date.current)
    end

    expect(DisplayAdEvent.where(created_at: days_ago_as_range(2)).count).to eq(5)

    described_class.rollup(Date.current - 2)

    results = DisplayAdEvent.where(created_at: days_ago_as_range(2))
    expect(results.count).to eq(3)
    expect(results.pluck(:display_ad_id)).to contain_exactly(ad1.id, ad1.id, ad2.id)
    expect(results.pluck(:user_id)).to contain_exactly(nil, nil, user1.id)
    expect(DisplayAdEvent.where("counts_for > 1").count).to eq(1)
  end
end
