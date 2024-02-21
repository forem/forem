require "rails_helper"

RSpec.describe PageViewRollup, type: :service do
  let(:article1) { create(:article) }
  let(:article2) { create(:article) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  def days_ago_as_range(num)
    (Date.current - num.days).all_day
  end

  it "fails if new attributes would be lost" do
    attributes_considered = described_class::ATTRIBUTES_PRESERVED + described_class::ATTRIBUTES_DESTROYED
    expect(PageView.column_names.map(&:to_sym)).to match_array(attributes_considered)
  end

  context "when compacting many rows" do
    before do
      create(:page_view, article: article1, user: nil)
      create(:page_view, article: article1, user: nil)
    end

    it "compacts one day's billboard_events" do
      # expect(BillboardEvent..count).to eq(5)

      expect do
        described_class.rollup(DateTime.current)
      end.to change { PageView.count }.from(2).to(1)

      # expectations = [
      #   [billboard1.id, nil, 3],
      #   [billboard1.id, user1.id, 1],
      #   [billboard2.id, nil, 1],
      # ]
      # results_mapped = BillboardEvent.where(created_at: days_ago_as_range(2)).map do |event|
      #   [event.billboard_id, event.user_id, event.counts_for]
      # end
      # expect(results_mapped).to match_array(expectations)
    end
  end

  # separate category
  it "groups by category" do
    create(:billboard_event, category: "impression", billboard: billboard1, user_id: nil)
    create(:billboard_event, category: "impression", billboard: billboard1, user_id: nil)
    create(:billboard_event, category: "impression", billboard: billboard1, user_id: nil)
    create(:billboard_event, category: "click", billboard: billboard1, user_id: nil)
    create(:billboard_event, category: "click", billboard: billboard1, user_id: nil)

    described_class.rollup(Date.current)
    results = BillboardEvent.where(created_at: Date.current.all_day)
    by_category = results.index_by { |r| r["category"] }
    expect(by_category["impression"]["counts_for"]).to eq(3)
    expect(by_category["click"]["counts_for"]).to eq(2)
  end

  # separate billboard_id
  it "groups by billboard_id" do
    create(:billboard_event, billboard: billboard1, user_id: nil)
    create(:billboard_event, billboard: billboard1, user_id: nil)
    create(:billboard_event, billboard: billboard1, user_id: nil)
    create(:billboard_event, billboard: billboard2, user_id: nil)
    create(:billboard_event, billboard: billboard2, user_id: nil)

    described_class.rollup(Date.current)
    results = BillboardEvent.where(created_at: Date.current.all_day)
    by_ad = results.index_by { |r| r["billboard_id"] }
    expect(by_ad[billboard1.id]["counts_for"]).to eq(3)
    expect(by_ad[billboard2.id]["counts_for"]).to eq(2)
  end

  # separate user_id / null
  it "groups by user_id (including null / logged-out user)" do
    create(:billboard_event, billboard: billboard1, user: user1)
    create(:billboard_event, billboard: billboard1, user: user2)
    create(:billboard_event, billboard: billboard1, user: user2)
    create(:billboard_event, billboard: billboard1, user: nil)
    create(:billboard_event, billboard: billboard1, user: nil)
    create(:billboard_event, billboard: billboard1, user: nil)
    create(:billboard_event, billboard: billboard1, user: nil)
    create(:billboard_event, billboard: billboard1, user: nil)

    described_class.rollup(Date.current)
    results = BillboardEvent.where(created_at: Date.current.all_day)
    by_user = results.index_by { |r| r["user_id"] }
    expect(by_user[user1.id]["counts_for"]).to eq(1)
    expect(by_user[user2.id]["counts_for"]).to eq(2)
    expect(by_user[nil]["counts_for"]).to eq(5)
  end

  # sums counts_for > 1
  it "counts previously crunched" do
    create(:billboard_event, billboard: billboard1, counts_for: 10, user_id: nil)
    create(:billboard_event, billboard: billboard1, counts_for: 15, user_id: nil)
    create(:billboard_event, billboard: billboard1, user_id: nil)
    create(:billboard_event, billboard: billboard1, user_id: nil)
    create(:billboard_event, billboard: billboard1, user_id: nil)

    described_class.rollup(Date.current)
    results = BillboardEvent.where(created_at: Date.current.all_day)
    expect(results.count).to eq(1)
    expect(results.first.counts_for).to eq(28)
  end
end
