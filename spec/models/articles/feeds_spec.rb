require "rails_helper"

RSpec.describe Articles::Feeds do
  describe ".lever_catalog" do
    subject { described_class.lever_catalog }

    it { is_expected.to be_a(Articles::Feeds::LeverCatalogBuilder) }
    it { is_expected.to be_frozen }
  end

  describe ".feed_for" do
    subject { described_class.feed_for(controller: controller, user: user, number_of_articles: 4, page: 1, tag: nil) }

    let(:controller) { double }
    let(:user) { nil }

    before { allow(AbExperiment).to receive(:get_feed_variant_for).and_return("original") }

    it { is_expected.to be_a(described_class::VariantQuery) }

    it "creates proper offset for page 2" do
      feed = described_class.feed_for(controller: controller, user: user, number_of_articles: 3, page: 2, tag: nil)
      expect(feed.call.to_sql).to include("OFFSET 3")
    end

    it "creates proper offset for page 4" do
      feed = described_class.feed_for(controller: controller, user: user, number_of_articles: 12, page: 4, tag: nil)
      expect(feed.call.to_sql).to include("OFFSET 36")
    end

    it "creates proper offset for page 1" do
      feed = described_class.feed_for(controller: controller, user: user, number_of_articles: 3, page: 1, tag: nil)
      expect(feed.call.to_sql).not_to include("OFFSET")
    end

    it "creates proper offset for page 0" do
      feed = described_class.feed_for(controller: controller, user: user, number_of_articles: 3, page: 0, tag: nil)
      expect(feed.call.to_sql).not_to include("OFFSET")
    end
  end
end
