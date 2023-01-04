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
      allow(Settings::SMTP).to receive(:address).and_return(nil)
      allow(Settings::SMTP).to receive(:user_name).and_return(nil)
      allow(Settings::SMTP).to receive(:password).and_return(nil)
      visit admin_config_path

      find("summary", text: "Email Server Settings (SMTP)").click
    end

    it "does not show the 'Use my own email server' checkbox" do
      within("form[data-testid='emailServerSettings']") do
        expect(page).not_to have_content("Use my own email server")
      end
    end

    it "shows the SMTP Form", :aggregate_failures do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_selector(".js-custom-smtp-section")
        expect(page).not_to have_selector(".js-custom-smtp-section.hidden")
      end
    end
  end

  context "when Sendgrid is enabled and SMTP is not enabled" do
    before do
      allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(true)
      allow(ForemInstance).to receive(:email).and_return("yo@forem.com")
      allow(Settings::SMTP).to receive(:address).and_return(nil)
      allow(Settings::SMTP).to receive(:user_name).and_return(nil)
      allow(Settings::SMTP).to receive(:password).and_return(nil)
      visit admin_config_path
      find("summary", text: "Email Server Settings (SMTP)").click
    end

    it "shows the checkbox to allow one to toggle ones own server" do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_content("Use my own email server")
      end
    end

    it "shows a description" do
      within("form[data-testid='emailServerSettings']") do
        # rubocop:disable Layout/LineLength
        expect(page).to have_content("As a Forem Cloud client, we provide an email server managed by the Forem team. All settings are managed by us and the from and reply email addresses are set as yo@forem.com. However, you can override this to use your own email server.")
        # rubocop:enable Layout/LineLength
      end
    end

    it "does not show an SMTP Form" do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_selector(".js-custom-smtp-section.hidden")
      end
    end
  end

  context "when Sendgrid is not enabled and SMTP is enabled" do
    before do
      allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(false)
      allow(Settings::SMTP).to receive(:address).and_return("smtp.gmail.com")
      allow(Settings::SMTP).to receive(:user_name).and_return("jane_doe")
      allow(Settings::SMTP).to receive(:password).and_return("abc123456")
      visit admin_config_path
      find("summary", text: "Email Server Settings (SMTP)").click
    end

    it "does not show the 'Use my own email server' checkbox" do
      within("form[data-testid='emailServerSettings']") do
        expect(page).not_to have_content("Use my own email server")
      end
    end

    it "shows the SMTP Form", :aggregate_failures do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_selector(".js-custom-smtp-section")
        expect(page).not_to have_selector(".js-custom-smtp-section.hidden")
      end
    end
  end

  context "when Sendgrid is enabled and SMTP is enabled" do
    before do
      allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(true)
      allow(Settings::SMTP).to receive(:address).and_return("smtp.gmail.com")
      allow(Settings::SMTP).to receive(:user_name).and_return("jane_doe")
      allow(Settings::SMTP).to receive(:password).and_return("abc123456")
      visit admin_config_path
      find("summary", text: "Email Server Settings (SMTP)").click
    end

    it "shows the 'Use my own email server' checkbox" do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_content("Use my own email server")
      end
    end

    it "shows an SMTP Form", :aggregate_failures do
      within("form[data-testid='emailServerSettings']") do
        expect(page).to have_selector(".js-custom-smtp-section")
        expect(page).not_to have_selector(".js-custom-smtp-section.hidden")
      end
    end
  end
end
