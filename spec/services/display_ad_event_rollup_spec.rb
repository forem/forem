require "rails_helper"

RSpec.describe DisplayAdEventRollup, type: :service do
  let(:ad1) { create :display_ad }
  let(:ad2) { create :display_ad }
  let(:user1) { create :user }
  let(:user2) { create :user }

  def override_timestamps
    DisplayAdEvent.record_timestamps = false
    yield
    DisplayAdEvent.record_timestamps = true
  end

  def days_ago_as_range(num)
    (Date.current - num.days).all_day
  end

  it "fails if new attributes would be lost" do
    attributes_considered = DisplayAdEventRollup::ATTRIBUTES_PRESERVED + DisplayAdEventRollup::ATTRIBUTES_DESTROYED
    expect(DisplayAdEvent.column_names.map(&:to_sym)).to contain_exactly(*attributes_considered)
  end

  context "when compacting many rows" do
    before do
      override_timestamps do
        create(:display_ad_event, created_at: Date.current - 2, display_ad: ad1, user_id: nil, updated_at: Date.current)
        create(:display_ad_event, created_at: Date.current - 2, display_ad: ad1, user_id: nil, updated_at: Date.current)
        create(:display_ad_event, created_at: Date.current - 2, display_ad: ad1, user_id: nil, updated_at: Date.current)

        create(:display_ad_event, created_at: Date.current - 2, display_ad: ad1, user_id: user1.id,
                                  updated_at: Date.current)
        create(:display_ad_event, created_at: Date.current - 2, display_ad: ad2, user_id: nil, updated_at: Date.current)
      end
    end

    it "compacts one day's display_ad_events" do
      expect(DisplayAdEvent.where(created_at: days_ago_as_range(2)).count).to eq(5)

      described_class.rollup(Date.current - 2)

      expectations = [
        [ad1.id, nil, 3],
        [ad1.id, user1.id, 1],
        [ad2.id, nil, 1],
      ]
      results_mapped = DisplayAdEvent.where(created_at: days_ago_as_range(2)).map do |event|
        [event.display_ad_id, event.user_id, event.counts_for]
      end
      expect(results_mapped).to contain_exactly(*expectations)
    end
  end

  # separate category
  it "groups by category" do
    create(:display_ad_event, category: "impression", display_ad: ad1, user_id: nil)
    create(:display_ad_event, category: "impression", display_ad: ad1, user_id: nil)
    create(:display_ad_event, category: "impression", display_ad: ad1, user_id: nil)
    create(:display_ad_event, category: "click", display_ad: ad1, user_id: nil)
    create(:display_ad_event, category: "click", display_ad: ad1, user_id: nil)

    described_class.rollup(Date.current)
    results = DisplayAdEvent.where(created_at: Date.current.all_day)
    by_category = results.index_by { |r| r["category"] }
    expect(by_category["impression"]["counts_for"]).to eq(3)
    expect(by_category["click"]["counts_for"]).to eq(2)
  end

  # separate display_ad_id
  it "groups by display_ad_id" do
    create(:display_ad_event, display_ad: ad1, user_id: nil)
    create(:display_ad_event, display_ad: ad1, user_id: nil)
    create(:display_ad_event, display_ad: ad1, user_id: nil)
    create(:display_ad_event, display_ad: ad2, user_id: nil)
    create(:display_ad_event, display_ad: ad2, user_id: nil)

    described_class.rollup(Date.current)
    results = DisplayAdEvent.where(created_at: Date.current.all_day)
    by_ad = results.index_by { |r| r["display_ad_id"] }
    expect(by_ad[ad1.id]["counts_for"]).to eq(3)
    expect(by_ad[ad2.id]["counts_for"]).to eq(2)
  end

  # separate user_id / null
  it "groups by user_id (including null / logged-out user)" do
    create(:display_ad_event, display_ad: ad1, user: user1)
    create(:display_ad_event, display_ad: ad1, user: user2)
    create(:display_ad_event, display_ad: ad1, user: user2)
    create(:display_ad_event, display_ad: ad1, user: nil)
    create(:display_ad_event, display_ad: ad1, user: nil)
    create(:display_ad_event, display_ad: ad1, user: nil)
    create(:display_ad_event, display_ad: ad1, user: nil)
    create(:display_ad_event, display_ad: ad1, user: nil)

    described_class.rollup(Date.current)
    results = DisplayAdEvent.where(created_at: Date.current.all_day)
    by_user = results.index_by { |r| r["user_id"] }
    expect(by_user[user1.id]["counts_for"]).to eq(1)
    expect(by_user[user2.id]["counts_for"]).to eq(2)
    expect(by_user[nil]["counts_for"]).to eq(5)
  end

  # sums counts_for > 1
  it "counts previously crunched" do
    create(:display_ad_event, display_ad: ad1, counts_for: 10, user_id: nil)
    create(:display_ad_event, display_ad: ad1, counts_for: 15, user_id: nil)
    create(:display_ad_event, display_ad: ad1, user_id: nil)
    create(:display_ad_event, display_ad: ad1, user_id: nil)
    create(:display_ad_event, display_ad: ad1, user_id: nil)

    described_class.rollup(Date.current)
    results = DisplayAdEvent.where(created_at: Date.current.all_day)
    expect(results.count).to eq(1)
    expect(results.first.counts_for).to eq(28)
  end
end
