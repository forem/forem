require "rails_helper"

RSpec.describe Settings::RateLimit, type: :model do
  describe ".trigger_spam_for?" do
    subject { described_class.trigger_spam_for?(text: text) }

    let(:text) { "text to test" }

    context "when it matches a spam trigger term" do
      before do
        allow(described_class).to receive(:spam_trigger_terms).and_return(["to test"])
      end

      it { is_expected.to be_truthy }
    end

    context "when there are no spam trigger terms" do
      before do
        allow(described_class).to receive(:spam_trigger_terms).and_return([])
      end

      it { is_expected.to be_falsey }
    end

    context "when there are spam trigger terms but they don't match" do
      before do
        allow(described_class).to receive(:spam_trigger_terms).and_return(["in a hole in the ground"])
      end

      it { is_expected.to be_falsey }
    end
  end
end
