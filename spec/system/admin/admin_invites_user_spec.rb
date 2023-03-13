require "rails_helper"

RSpec.describe "Admin invites user" do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
  end

  context "when SMTP is not configured" do
    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(false)
      visit new_admin_invitation_path
    end

    it "shows a header" do
      header = "Setup SMTP to invite users"
      expect(page).to have_content(header)
    end

    it "shows a banner" do
      message = "SMTP settings are required so that your Forem can send emails. If you wish to send invites, " \
                "email digests and activity notifications you will need to specify which email host will relay those " \
                "messages for you."
      expect(page).to have_content(message)
    end

    it "contains a link to the documentation" do
      expect(page).to have_link("read more about SMTP Settings in our admin guide")
    end

    it "contains a link to configure SMTP settings" do
      expect(page).to have_link("Configure your SMTP Settings", href: admin_config_path(anchor: "smtp-section"))
    end

    it "does not contain any for fields" do
      expect(page).not_to have_field "Email"
    end

    it "does not contain any submit buttons" do
      expect(page).not_to have_button "Invite User"
    end
  end

  context "when SMTP is configured" do
    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
      visit new_admin_invitation_path
    end

    it "shows the input field" do
      expect(page).to have_field "Email"
    end

    it "shows the submit button" do
      expect(page).to have_button "Invite User"
    end
  end
end
