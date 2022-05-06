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
  end
end
