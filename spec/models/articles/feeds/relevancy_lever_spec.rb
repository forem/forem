require "rails_helper"

RSpec.describe Articles::Feeds::RelevancyLever do
  subject { lever }

  let(:lever) do
    described_class.new(
      key: :my_key,
      range: "[0..10)",
      label: "My label",
      select_fragment: "articles.reaction_count",
      user_required: true,
    )
  end

  it { is_expected.to respond_to :key }
  it { is_expected.to respond_to :label }
  it { is_expected.to respond_to :select_fragment }
  it { is_expected.to respond_to :joins_fragments }
  it { is_expected.to respond_to :group_by_fragment }
  it { is_expected.to respond_to :user_required }
  it { is_expected.to respond_to :user_required? }

  describe "#configure_with" do
    subject { lever.configure_with(fallback: fallback, cases: cases) }

    let(:cases) { [[0, 0]] }
    let(:fallback) { 1 }

    context "when fallback is not a number" do
      let(:fallback) { "nope" }

      it { within_block_is_expected.to raise_error described_class::InvalidFallbackError }
    end

    context "when cases is not an array" do
      let(:cases) { "nope" }

      it { within_block_is_expected.to raise_error described_class::InvalidCasesError }
    end

    context "when cases includes a non-number" do
      let(:cases) { [[0, 1], [1, "a"]] }

      it { within_block_is_expected.to raise_error described_class::InvalidCasesError }
    end

    context "when lever has query parameters" do
      let(:lever) do
        described_class.new(
          key: :my_key,
          range: "[0..10)",
          label: "My label",
          select_fragment: "articles.reaction_count",
          user_required: true,
          query_parameter_names: [:threshold],
        )
      end

      it "sets the configured query parameters" do
        configuration = lever.configure_with(fallback: fallback, cases: cases, threshold: 1)
        expect(configuration.query_parameters).to eq({ threshold: 1 })
      end

      it "raises InvalidQueryParametersError when not provided" do
        expect { lever.configure_with(fallback: fallback, cases: cases) }
          .to raise_error(described_class::InvalidQueryParametersError)
      end
    end
  end
end
