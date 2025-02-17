require "rails_helper"

RSpec.describe FeedbackMessage do
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
          .with_message(described_class.reporter_uniqueness_msg)
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

  describe ".all_user_reports" do
    let(:user) { create(:user) }

    it "returns reported feedback messages" do
      report = create(:feedback_message, reporter: user)

      expect(described_class.all_user_reports(user).first.id).to eq(report.id)
    end

    it "returns affected feedback messages" do
      report = create(:feedback_message, affected: user)

      expect(described_class.all_user_reports(user).first.id).to eq(report.id)
    end

    it "returns offender feedback messages" do
      report = create(:feedback_message, offender: user)

      expect(described_class.all_user_reports(user).first.id).to eq(report.id)
    end
  end

  describe "#determine_reported_from_url" do
    let(:billboard) { create(:billboard) }
    let(:article) { create(:article) }
    let(:comment) { create(:comment) }
    let(:user) { create(:user) }

    context "when the URL matches a Billboard" do
      let(:feedback_message) { create(:feedback_message, :abuse_report, reported_url: "/admin/customization/billboards/#{billboard.id}") }

      it "sets the reported object to the corresponding Billboard" do
        feedback_message.determine_reported_from_url
        expect(feedback_message.reported).to eq(billboard)
      end
    end

    context "when the URL matches an Article" do
      let(:feedback_message) { create(:feedback_message, :abuse_report, reported_url: article.path) }

      it "sets the reported object to the corresponding Article" do
        feedback_message.determine_reported_from_url
        expect(feedback_message.reported).to eq(article)
      end
    end

    context "when the URL matches a Comment" do
      let(:feedback_message) { create(:feedback_message, :abuse_report, reported_url: comment.path) }

      it "sets the reported object to the corresponding Comment" do
        feedback_message.determine_reported_from_url
        expect(feedback_message.reported).to eq(comment)
      end
    end

    context "when the URL matches a User" do
      let(:feedback_message) { create(:feedback_message, :abuse_report, reported_url: "/#{user.username}") }

      it "sets the reported object to the corresponding User" do
        feedback_message.determine_reported_from_url
        expect(feedback_message.reported).to eq(user)
      end
    end

    context "when the URL does not match any entity" do
      let(:feedback_message) { create(:feedback_message, :abuse_report, reported_url: "/nonexistent/path") }

      it "does not set the reported object" do
        feedback_message.determine_reported_from_url
        expect(feedback_message.reported).to be_nil
      end
    end
  end
end
