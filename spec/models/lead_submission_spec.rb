require "rails_helper"

RSpec.describe LeadSubmission do
  describe "validations" do
    subject { create(:lead_submission) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_lead_form_id).with_message(I18n.t("models.lead_submission.already_submitted")) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:organization_lead_form) }
    it { is_expected.to belong_to(:user) }
  end

  describe ".snapshot_from_user" do
    it "captures user profile data" do
      user = create(:user, name: "Jane Doe", email: "jane@example.com")
      user.profile.update(location: "New York")

      snapshot = described_class.snapshot_from_user(user)

      expect(snapshot[:name]).to eq("Jane Doe")
      expect(snapshot[:email]).to eq("jane@example.com")
      expect(snapshot[:location]).to eq("New York")
    end
  end
end
