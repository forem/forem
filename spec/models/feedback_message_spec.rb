require "rails_helper"

RSpec.describe FeedbackMessage, type: :model do
  subject(:feedback_message) { create(:feedback_message) }

  it { is_expected.to validate_presence_of(:feedback_type) }
  it { is_expected.to validate_presence_of(:message) }
  it { is_expected.to validate_length_of(:reported_url).is_at_most(250) }
  it { is_expected.to validate_length_of(:message).is_at_most(2500) }

  it do
    expect(feedback_message).to validate_inclusion_of(:category)
      .in_array(["spam", "other", "rude or vulgar", "harassment", "bug"])
  end

  it do
    expect(feedback_message).to validate_inclusion_of(:status)
      .in_array(%w[Open Invalid Resolved])
  end

  describe "validations for an abuse report" do
    subject(:feedback_message) { create(:feedback_message, :abuse_report) }

    it { is_expected.to validate_presence_of(:reported_url) }
    it { is_expected.to validate_uniqueness_of(:reporter_id).scoped_to(%i[reported_url feedback_type]) }
    it { is_expected.to validate_length_of(:reported_url).is_at_most(250) }
    it { is_expected.to validate_presence_of(:category) }
  end

  describe "validations for a bug report" do
    subject(:feedback_message) { create(:feedback_message, :bug_report) }

    it { is_expected.not_to validate_presence_of(:reported_url) }
  end

  describe "validations without a reporter_id" do
    subject(:feedback_message) { build(:feedback_message, :abuse_report, reporter_id: nil) }

    it { is_expected.not_to validate_uniqueness_of(:reporter_id).scoped_to(%i[reported_url feedback_type]) }
  end
end
