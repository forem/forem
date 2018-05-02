require "rails_helper"

RSpec.describe ScholarshipMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "#scholarship_awarded_email" do
    it "renders proper subject" do
      user = create(:user)
      scholarship_awarded_email = described_class.scholarship_awarded_email(user)
      expect(scholarship_awarded_email.subject).to eq("Congrats on your DEV Scholarship!")
    end

    it "renders proper receiver" do
      user = create(:user)
      scholarship_awarded_email = described_class.scholarship_awarded_email(user)
      expect(scholarship_awarded_email.to).to eq([user.email])
    end
  end
end
