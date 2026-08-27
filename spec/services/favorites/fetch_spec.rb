require "rails_helper"

RSpec.describe Favorites::Fetch, type: :service do
  let(:leader) { create(:user) }
  let(:other_leader) { create(:user) }

  def favorite(favoritable, user, favorited_at)
    favoritable.update_columns(favorited_by_user_id: user.id, favorited_at: favorited_at)
    favoritable
  end

  context "when scoped to a user" do
    it "returns that user's favorited articles and comments" do
      article = favorite(create(:article), leader, 1.hour.ago)
      comment = favorite(create(:comment, commentable: create(:article)), leader, 2.hours.ago)

      expect(described_class.call(user: leader)).to eq([article, comment])
    end

    it "excludes favorites claimed by other users" do
      favorite(create(:article), other_leader, 1.hour.ago)

      expect(described_class.call(user: leader)).to be_empty
    end

    it "excludes unfavorited content" do
      create(:article)
      create(:comment, commentable: create(:article))

      expect(described_class.call(user: leader)).to be_empty
    end

    it "orders by favorited_at, newest first" do
      older = favorite(create(:article), leader, 3.days.ago)
      newer = favorite(create(:article), leader, 1.day.ago)

      expect(described_class.call(user: leader)).to eq([newer, older])
    end
  end

  context "without a user" do
    it "returns favorites claimed by any user" do
      article = favorite(create(:article), leader, 1.hour.ago)
      comment = favorite(create(:comment, commentable: create(:article)), other_leader, 2.hours.ago)

      expect(described_class.call).to eq([article, comment])
    end

    it "excludes unfavorited content" do
      create(:article)
      create(:comment, commentable: create(:article))

      expect(described_class.call).to be_empty
    end
  end

  describe "pagination" do
    it "returns only the requested page" do
      newer = favorite(create(:article), leader, 1.day.ago)
      older = favorite(create(:article), leader, 2.days.ago)

      expect(described_class.call(user: leader, page: 1, per_page: 1)).to eq([newer])
      expect(described_class.call(user: leader, page: 2, per_page: 1)).to eq([older])
    end

    it "reports the total count across both types" do
      favorite(create(:article), leader, 1.day.ago)
      favorite(create(:comment, commentable: create(:article)), leader, 2.days.ago)

      result = described_class.call(user: leader, page: 1, per_page: 1)

      expect(result.total_count).to eq(2)
      expect(result.total_pages).to eq(2)
      expect(result.current_page).to eq(1)
    end

    it "treats a nil page as the first page" do
      article = favorite(create(:article), leader, 1.day.ago)

      expect(described_class.call(user: leader, page: nil)).to eq([article])
    end
  end
end
