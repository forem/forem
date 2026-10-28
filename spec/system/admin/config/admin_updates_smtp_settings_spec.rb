require "rails_helper"

RSpec.describe "Admin updates SMTP Settings" do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
  end

  # We're unable to set and unset an ENV variable in Cypress to test different scenarios
  # hence, we test the view layouts with Capybara, and we test successful updates with Cypress.
  context "when Sendgrid is not enabled and SMTP is not enabled" do
    before do
      allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(false)
      allow(Settings::SMTP).to receive_messages(address: nil, user_name: nil, password: nil)
      visit admin_config_path

      find("summary", text: "Email Server Settings (SMTP)").click
    end

    it "hides the 'Use my own email server' checkbox and shows the SMTP form", :aggregate_failures do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_no_content("Use my own email server")
        expect(page).to have_css(".js-custom-smtp-section")
        expect(page).to have_no_css(".js-custom-smtp-section.hidden")
      end
    end
  end

  context "when Sendgrid is enabled and SMTP is not enabled" do
    before do
      allow(ForemInstance).to receive_messages(sendgrid_enabled?: true, email: "yo@example.com")
      allow(Settings::SMTP).to receive_messages(address: nil, user_name: nil, password: nil)
      visit admin_config_path
      find("summary", text: "Email Server Settings (SMTP)").click
    end

    it "shows the toggle checkbox and description while hiding the SMTP form", :aggregate_failures do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_content("Use my own email server")
        # rubocop:disable Layout/LineLength
        expect(page).to have_content("As a Forem Cloud client, we provide an email server managed by the Forem team. All settings are managed by us and the from and reply email addresses are set as yo@example.com. However, you can override this to use your own email server.")
        # rubocop:enable Layout/LineLength
        expect(page).to have_css(".js-custom-smtp-section.hidden")
      end
    end
  end

  context "when Sendgrid is not enabled and SMTP is enabled" do
    before do
      allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(false)
      allow(Settings::SMTP).to receive_messages(address: "smtp.gmail.com", user_name: "jane_doe", password: "abc123456")
      visit admin_config_path
      find("summary", text: "Email Server Settings (SMTP)").click
    end

    it "hides the 'Use my own email server' checkbox and shows the SMTP form", :aggregate_failures do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_no_content("Use my own email server")
        expect(page).to have_css(".js-custom-smtp-section")
        expect(page).to have_no_css(".js-custom-smtp-section.hidden")
      end
    end
  end

  context "when Sendgrid is enabled and SMTP is enabled" do
    before do
      allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(true)
      allow(Settings::SMTP).to receive_messages(address: "smtp.gmail.com", user_name: "jane_doe", password: "abc123456")
      visit admin_config_path
      find("summary", text: "Email Server Settings (SMTP)").click
    end

    it "shows the 'Use my own email server' checkbox and the SMTP form", :aggregate_failures do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_content("Use my own email server")
        expect(page).to have_css(".js-custom-smtp-section")
        expect(page).to have_no_css(".js-custom-smtp-section.hidden")
      end
    end
  end
end
