require "rails_helper"

RSpec.describe FeedbackMessage, type: :model do
  let(:reporter) { create(:user) }
  let(:abuse_report) { create(:feedback_message, :abuse_report, reporter: reporter) }

  describe "validations" do
    describe "builtin validations" do
      subject(:feedback_message) { create(:feedback_message) }

      it { is_expected.to belong_to(:offender).class_name("User").inverse_of(:offender_feedback_messages).optional }
      it { is_expected.to belong_to(:reporter).class_name("User").inverse_of(:reporter_feedback_messages).optional }
      it { is_expected.to belong_to(:affected).class_name("User").inverse_of(:affected_feedback_messages).optional }

      it { is_expected.to have_one(:email_message).dependent(:nullify).optional }
      it { is_expected.to have_many(:notes).inverse_of(:noteable).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:feedback_type) }
      it { is_expected.to validate_presence_of(:message) }
      it { is_expected.to validate_length_of(:reported_url).is_at_most(250) }
      it { is_expected.to validate_length_of(:message).is_at_most(2500) }

      it do
        expect(feedback_message).to validate_inclusion_of(:category)
          .in_array(described_class::CATEGORIES)
      end

      it do
        expect(feedback_message).to validate_inclusion_of(:status)
          .in_array(described_class::STATUSES)
      end
    end

    describe "validations for an abuse report" do
      subject(:feedback_message) { abuse_report }

      it { is_expected.to validate_presence_of(:reported_url) }

      it do
        expect(feedback_message).to validate_uniqueness_of(:reporter_id)
          .scoped_to(described_class::REPORTER_UNIQUENESS_SCOPE)
          .with_message(described_class::REPORTER_UNIQUENESS_MSG)
      end

      it { is_expected.to validate_length_of(:reported_url).is_at_most(250) }
      it { is_expected.to validate_presence_of(:category) }

      it "does not check for uniqueness if the new abuse report does not have a reporter id" do
        new_abuse_report = build(:feedback_message, :abuse_report)
        new_abuse_report.reported_url = abuse_report.reported_url

        expect(new_abuse_report).to be_valid
      end
    end

    describe "validations for a bug report" do
      subject(:feedback_message) { create(:feedback_message, :bug_report, reporter: reporter) }

      it { is_expected.not_to validate_presence_of(:reported_url) }
    end
  end
end
