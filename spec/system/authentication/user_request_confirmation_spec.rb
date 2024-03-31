require "rails_helper"

RSpec.describe "/confirm-email" do
  it "stays on the same page and displays a flash message", :aggregate_failures do
    visit confirm_email_path
    fill_in "user_email", with: "test@example.com"
    click_button "Resend"

    expect(page).to have_current_path(user_confirmation_path)
    expected_message = I18n.t("confirmations_controller.email_sent", email: ForemInstance.contact_email)
    expect(page).to have_content(expected_message)
  end
end
