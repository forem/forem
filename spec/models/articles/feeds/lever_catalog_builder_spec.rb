require "rails_helper"

RSpec.describe Articles::Feeds::LeverCatalogBuilder do
  let(:catalog) do
    described_class.new do
      order_by_lever(:order_by_this,
                     label: "Hello world",
                     order_by_fragment: "relevancy_score DESC")

      relevancy_lever(:my_key,
                      user_required: true,
                      label: "A label",
                      range: "[-10..0]",
                      select_fragment: "articles.count")

      relevancy_lever(:my_other_key,
                      user_required: false,
                      label: "Another label",
                      range: "[-10..0]",
                      select_fragment: "articles.reactions_count")
    end
  end

  describe ".new" do
    subject { catalog }

    it { is_expected.to be_a(described_class) }
    it { is_expected.to be_frozen }

    it "raise a DuplicateLeverError when configured with a duplicate relevancy_lever key" do
      expect do
        described_class.new do
          relevancy_lever(:my_key,
                          user_required: true,
                          label: "A label",
                          range: "[-10..0]",
                          select_fragment: "articles.count")

          relevancy_lever(:my_key,
                          user_required: false,
                          label: "Another label",
                          range: "[-10..0]",
                          select_fragment: "articles.reactions_count")
        end
      end.to raise_error(described_class::DuplicateLeverError)
    end

    it "raise a DuplicateLeverError when configured with a duplicate order_by_lever key" do
      expect do
        described_class.new do
          order_by_lever(:my_key,
                         label: "A label",
                         order_by_fragment: "articles.count")

          order_by_lever(:my_key,
                         label: "Another label",
                         order_by_fragment: "articles.reactions_count")
        end
      end.to raise_error(described_class::DuplicateLeverError)
    end
  end

  describe "#fetch_lever" do
    subject { catalog.fetch_lever(key) }

    context "when lever exists" do
      let(:key) { "my_key" }

      it { is_expected.to be_a(Articles::Feeds::RelevancyLever) }
      it { is_expected.to be_frozen }
    end

    context "when lever does not exist" do
      let(:key) { "404" }

      it { within_block_is_expected.to raise_error(KeyError) }
    end
  end

  describe "#fetch_order_by" do
    subject { catalog.fetch_order_by(key) }

    context "when lever exists" do
      let(:key) { "order_by_this" }

      it { is_expected.to be_a(Articles::Feeds::OrderByLever) }
      it { is_expected.to be_frozen }
    end

    context "when lever does not exist" do
      let(:key) { "404" }

      it { within_block_is_expected.to raise_error(KeyError) }
    end
  end
end
