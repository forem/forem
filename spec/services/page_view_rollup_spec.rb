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
    it "does not compact signed-in user's views" do
      user_view1 = create(:page_view, article: article1, user: user1, created_at: 2.days.ago)
      user_view2 = create(:page_view, article: article1, user: user1, created_at: 2.days.ago)
      rando_view1 = create(:page_view, article: article1, user: nil, created_at: 2.days.ago)
      rando_view2 = create(:page_view, article: article1, user: nil, created_at: 2.days.ago)

      expect do
        described_class.rollup(2.days.ago)
      end.to change(PageView, :count).from(4).to(3)

      expect(user_view1.reload).to be_persisted
      expect(user_view2.reload).to be_persisted
      expect(PageView.where(id: [rando_view1.id, rando_view2.id])).to be_empty
    end

    it "compacts by the hour" do
      [[1, 59], [1, 0], [3, 0], [3, 1], [3, 2]].each do |hour, min|
        create(:page_view, article: article1, user: nil, created_at: 2.days.ago.change(hour: hour, min: min))
      end

      expect do
        described_class.rollup(2.days.ago)
      end.to change(PageView, :count).from(5).to(2)

      results_plucked = PageView.where(created_at: days_ago_as_range(2))
        .pluck(:article_id, :user_id, :counts_for_number_of_views, :time_tracked_in_seconds)

      expect(results_plucked).to contain_exactly(
        [article1.id, nil, 2, 30],
        [article1.id, nil, 3, 45],
      )
    end

    it "does not compact views outside of the same hour" do
      24.times do |hour|
        create(:page_view, article: article1, user: nil, created_at: 2.days.ago.change(hour: hour))
      end

      expect do
        described_class.rollup(2.days.ago)
      end.not_to change(PageView, :count)
    end
  end

  it "only compacts views of the same article" do
    create(:page_view, article: article1, user: nil, created_at: 2.days.ago)
    create(:page_view, article: article1, user: nil, created_at: 2.days.ago)
    create(:page_view, article: article2, user: nil, created_at: 2.days.ago)
    create(:page_view, article: article2, user: nil, created_at: 2.days.ago)

    expect do
      described_class.rollup(2.days.ago)
    end.to change(PageView, :count).from(4).to(2)
    expect(PageView.pluck(:article_id,
                          :counts_for_number_of_views)).to contain_exactly([article1.id, 2], [article2.id, 2])
  end
end
