require "rails_helper"

RSpec.describe ScholarshipMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "#scholarship_awarded_email" do
    it "renders proper subject" do
      email = described_class.scholarship_awarded_email(user)
      expect(email.subject).to eq("Congrats on your DEV Scholarship!")
    end

    it "renders proper from" do
      email = described_class.scholarship_awarded_email(user)
      expect(email.from).to eq(["members@dev.to"])
      expect(email["from"].value).to eq("members@dev.to")
    end

    it "renders proper receiver" do
      email = described_class.scholarship_awarded_email(user)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.scholarship_awarded_email(user)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.scholarship_awarded_email(user)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=scholarship_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=scholarship_awarded_email"))
    end
  end
end
