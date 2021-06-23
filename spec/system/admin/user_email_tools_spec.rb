require "rails_helper"

RSpec.describe "Admin Email Tools within User management", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:email_subject) { "Email subject" }
  let(:email_body) { "Email body" }

  context "when looking at a user with recorded emails in the admin panel" do
    before do
      sign_in admin
      visit admin_user_path(user)

      # Send the test user an email using the built in form
      within(:css, "#user-email-tools") do
        fill_in("email_subject", with: email_subject)
        fill_in("email_body", with: email_body)
        click_on("Send Email")
      end

      visit admin_user_path(user)
    end

    it "shows the email sent to the user" do
      email_tools_section = find("#user-email-tools")
      expect(email_tools_section).to have_text(email_subject)
    end

    it "redirects and displays the email details" do
      within(:css, "#user-email-tools") do
        all("a.list-group-item-action").first.click
      end

      expect(page).to have_content(email_subject)
      expect(page).to have_content(email_body)
      expect(page).to have_content("NotifyMailer#user_contact_email")
      expect(page).to have_content(user.email)
    end
  end
end
