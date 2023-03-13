require "rails_helper"

RSpec.describe Collection do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, :with_articles, user: user) }

  describe "validations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to have_many(:articles).dependent(:nullify) }

    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:user_id) }
  end

  describe ".find_series" do
    let!(:other_user) { create(:user) }
    let!(:series) { collection }

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

  describe "path" do
    it "returns the correct path" do
      expect(collection.path).to eq("/#{collection.user.username}/series/#{collection.id}")
    end
  end

  context "when callbacks are triggered after touch" do
    it "touches all articles in the collection" do
      before_times = collection.articles.order(updated_at: :desc).pluck(:updated_at).map(&:to_i)

      Timecop.freeze(1.month.from_now) do
        collection.touch
      end

      after_times = collection.reload.articles.order(updated_at: :desc).pluck(:updated_at).map(&:to_i)

      all_before = after_times.each_with_index.map { |v, i| v > before_times[i] }
      expect(all_before.all?).to be(true)
    end
  end
end
