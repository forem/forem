require "rails_helper"

RSpec.describe LeadSubmission do
  describe "validations" do
    subject { create(:lead_submission) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_lead_form_id).with_message(I18n.t("models.lead_submission.already_submitted")) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:organization_lead_form) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe ".snapshot_from_user" do
    it "captures user profile data and username, excluding location" do
      user = create(:user, name: "Jane Doe", email: "jane@example.com")
      user.profile.update!(location: "New York")

      allow(user.profile).to receive(:read_attribute).and_call_original
      allow(user.profile).to receive(:read_attribute).with(:job_title).and_return("Software Engineer")
      allow(user.profile).to receive(:read_attribute).with(:company).and_return("Acme Inc.")

      snapshot = described_class.snapshot_from_user(user)

      expect(snapshot[:name]).to eq("Jane Doe")
      expect(snapshot[:email]).to eq("jane@example.com")
      expect(snapshot[:job_title]).to eq("Software Engineer")
      expect(snapshot[:company]).to eq("Acme Inc.")
      expect(snapshot[:username]).to eq(user.username)
      expect(snapshot).not_to have_key(:location)
    end
  end
end
