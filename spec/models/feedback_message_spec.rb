require "rails_helper"

RSpec.describe FeedbackMessage, type: :model do
  let(:user) { create(:user) }
  let(:abuse_report) { create(:feedback_message, :abuse_report) }

  describe "validations for an abuse report" do
    subject(:feedback_message) do
      described_class.new(
        feedback_type: "abuse-reports",
        reported_url: "https://dev.to",
        category: "spam",
        message: "something",
      )
    end

    it { is_expected.to validate_presence_of(:feedback_type) }
    it { is_expected.to validate_presence_of(:reported_url) }
    it { is_expected.to validate_presence_of(:message) }

    it do
      expect(feedback_message).to validate_inclusion_of(:category).
        in_array(["spam", "other", "rude or vulgar", "harassment", "bug"])
    end
  end

  describe "validations for a bug report" do
    subject(:feedback_message) do
      described_class.new(
        feedback_type: "bug-reports",
        category: "bug",
        message: "something",
      )
    end

    it { is_expected.to validate_presence_of(:feedback_type) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.not_to validate_presence_of(:reported_url) }

    it do
      expect(feedback_message).to validate_inclusion_of(:category).
        in_array(["spam", "other", "rude or vulgar", "harassment", "bug"])
    end
  end
end
