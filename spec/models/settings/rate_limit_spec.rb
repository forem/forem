require "rails_helper"

RSpec.describe Settings::RateLimit do
  describe ".user_considered_new?" do
    subject(:function_call) { described_class.user_considered_new?(user: user) }

    before do
      allow(described_class).to receive(:user_considered_new_days).and_return(5)
    end

    context "when given a nil user" do
      let(:user) { nil }

      it { is_expected.to be_truthy }
    end

    context "when given a decorated user that was created months ago" do
      let(:user) { create(:user).decorate }

      before { allow(user).to receive(:created_at).and_return(30.months.ago) }

      it { is_expected.to be_falsey }
    end

    context "when given a decorated user that was created within the user_considered_new_days" do
      let(:user) { create(:user).decorate }

      before { allow(user).to receive(:created_at).and_return(3.days.ago) }

      it { is_expected.to be_truthy }
    end
  end

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
