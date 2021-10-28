require "rails_helper"

RSpec.describe "Admin invites user", type: :system do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
    visit new_admin_invitation_path
  end

  context "when SMTP is not configured" do
    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(false)
    end

    it "shows a banner" do
      message = "SMTP settings are required so that your Forem can send emails. If you wish to send invites,"\
                "email digests and activity notifications you will need to specify which email host will relay those"\
                "messages for you."
      expect(page).to have_content(message)
    end

    it "contains a link to the documentation" do
      expect(page).to have_link(href: "https://admin.forem.com/docs/advanced-customization/config/smtp-settings")
    end

    it "contains a link to configure SMTP settings" do
      expect(page).to have_link("Configure SMTP Settings", href: admin_config_path(anchor: "smtp-section"))
    end

    it "disables the input fields" do
      expect(page).to have_field "Email", disabled: true
      expect(page).to have_field "Name", disabled: true
    end

    it "disables the submit button" do
      expect(page).to have_button "Invite User", disabled: true
    end
  end
end
