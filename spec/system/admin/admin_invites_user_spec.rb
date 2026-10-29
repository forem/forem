require "rails_helper"

RSpec.describe "Admin invites user" do
  let(:admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }

  before do
    sign_in admin
  end

  context "when SMTP is not configured" do
    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(false)
      visit new_admin_invitation_path
    end

    it "shows the SMTP setup prompt and links without the invitation form", :aggregate_failures do
      header = "Setup SMTP to invite users"
      message = "SMTP settings are required so that your Forem can send emails. If you wish to send invites, " \
                "email digests and activity notifications you will need to specify which email host will relay those " \
                "messages for you."

      expect(page).to have_content(header)
      expect(page).to have_content(message)
      expect(page).to have_link("read more about SMTP Settings in our admin guide")
      expect(page).to have_link("Configure your SMTP Settings", href: admin_config_path(anchor: "smtp-section"))
      expect(page).to have_no_field "Email"
      expect(page).to have_no_button "Invite User"
    end
  end

  context "when SMTP is configured" do
    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
      visit new_admin_invitation_path
    end

    it "shows the input field and submit button", :aggregate_failures do
      expect(page).to have_field "Email"
      expect(page).to have_button "Invite User"
    end
  end
end
