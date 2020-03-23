require "rails_helper"

RSpec.describe Collection, type: :model do
  let_it_be(:user) { create(:user) }
  let_it_be(:collection) { create(:collection, :with_articles, user: user) }

  describe "validations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:articles) }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:user_id) }
  end

  describe ".find_series" do
    let_it_be(:other_user) { create(:user) }
    let_it_be(:series) { collection }

    it "returns an existing series" do
      expect do
        expect(described_class.find_series(series.slug, series.user)).to eq(series)
      end.not_to change(described_class, :count)
    end

    it "creates a new series for a user if an existing one is not found" do
      slug = Faker::Books::CultureSeries.book
      expect { described_class.find_series(slug, other_user) }.to change(described_class, :count).by(1)
    end

    it "creates a new series with an existing slug for a new user" do
      expect { described_class.find_series(series.slug, other_user) }.to change(described_class, :count).by(1)
    end
  end

  describe "#touch_articles" do
    it "touches all articles in the collection" do
      Timecop.freeze(DateTime.parse("2019/10/24")) do
        allow(collection.articles).to receive(:update_all)
        collection.touch_articles
        expect(collection.articles).to have_received(:update_all).with(updated_at: Time.current)
      end
    end
  end

  describe "when the collection is touched" do
    it "touches each article in the collection" do
      allow(collection).to receive(:touch_articles)
      collection.touch
      expect(collection).to have_received(:touch_articles)
    end
  end
end
