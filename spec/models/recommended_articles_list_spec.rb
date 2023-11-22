require "rails_helper"

RSpec.describe RecommendedArticlesList do
  # Test associations
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  # Test validations
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(120) }
  end

  # Test scopes
  describe ".active" do
    let!(:active_list) { create(:recommended_articles_list, expires_at: 2.days.from_now) }
    let!(:inactive_list) { create(:recommended_articles_list, expires_at: 2.days.ago) }

    it "includes lists that have not expired" do
      expect(described_class.active).to include(active_list)
    end

    it "excludes lists that have expired" do
      expect(described_class.active).not_to include(inactive_list)
    end
  end

  # Test callbacks
  describe "before_save" do
    context "when expires_at is not set" do
      let(:user) { create(:user) }
      let(:list) { build(:recommended_articles_list, expires_at: nil, user: user) }

      it "sets expires_at to one day from now" do
        Timecop.freeze(Time.current) do
          list.save!
          expect(list.reload.expires_at).to be_within(5.seconds).of(1.day.from_now)
        end
      end
    end
  end

  # Test custom methods
  describe "#article_ids=" do
    let(:list) { build(:recommended_articles_list) }

    context "when input is a comma-separated string" do
      it "converts it to an array of integers" do
        list.article_ids = "1,2,3"
        expect(list.article_ids).to eq([1, 2, 3])
      end
    end

    context "when input is an array" do
      it "keeps it as an array of integers" do
        list.article_ids = [1, 2, 3]
        expect(list.article_ids).to eq([1, 2, 3])
      end
    end

    context "when input includes nil or empty values" do
      it "filters out invalid entries" do
        list.article_ids = [1, "", nil, 3]
        expect(list.article_ids).to eq([1, 3])
      end
    end
  end
end
