require "rails_helper"

RSpec.describe BillboardEventRollup, type: :service do
  let(:billboard1) { create(:billboard) }
  let(:billboard2) { create(:billboard) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  def override_timestamps
    BillboardEvent.record_timestamps = false
    yield
    BillboardEvent.record_timestamps = true
  end

  def days_ago_as_range(num)
    (Date.current - num.days).all_day
  end

  it "handles statement timeout when compacting records" do
    override_timestamps do
      create_list(:billboard_event, 10, created_at: Date.current - 2, billboard: billboard1, user_id: user1.id,
                                        updated_at: Date.current)
    end

    allow(BillboardEvent.connection).to receive(:execute).and_call_original

    expect do
      described_class.rollup(Date.current - 2)
    end.not_to raise_error

    expect(BillboardEvent.connection).to have_received(:execute)
      .with("SET LOCAL statement_timeout = '#{BillboardEventRollup::STATEMENT_TIMEOUT}s'").twice
    expect(BillboardEvent.connection).to have_received(:execute).with("RESET statement_timeout").thrice
  end

  it "fails if new attributes would be lost" do
    attributes_considered = described_class::ATTRIBUTES_PRESERVED + described_class::ATTRIBUTES_DESTROYED
    expect(BillboardEvent.column_names.map(&:to_sym)).to match_array(attributes_considered)
  end

  context "when compacting many rows" do
    before do
      override_timestamps do
        create(:billboard_event, created_at: Date.current - 2, billboard: billboard1, user_id: nil,
                                 updated_at: Date.current)
        create(:billboard_event, created_at: Date.current - 2, billboard: billboard1, user_id: nil,
                                 updated_at: Date.current)
        create(:billboard_event, created_at: Date.current - 2, billboard: billboard1, user_id: nil,
                                 updated_at: Date.current)

        create(:billboard_event, created_at: Date.current - 2, billboard: billboard1, user_id: user1.id,
                                 updated_at: Date.current)
        create(:billboard_event, created_at: Date.current - 2, billboard: billboard2, user_id: nil,
                                 updated_at: Date.current)
      end
    end

    it "compacts one day's billboard_events" do
      expect(BillboardEvent.where(created_at: days_ago_as_range(2)).count).to eq(5)

      described_class.rollup(Date.current - 2)

      expectations = [
        [billboard1.id, nil, 3],
        [billboard1.id, user1.id, 1],
        [billboard2.id, nil, 1],
      ]
      results_mapped = BillboardEvent.where(created_at: days_ago_as_range(2)).map do |event|
        [event.billboard_id, event.user_id, event.counts_for]
      end
      expect(results_mapped).to match_array(expectations)
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
