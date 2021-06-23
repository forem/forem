require "rails_helper"

RSpec.describe "/confirm-email", type: :system do
  it "stays on the same page and displays a flash message", :aggregate_failures do
    visit confirm_email_path
    fill_in "user_email", with: "test@example.com"
    click_button "Resend confirmation instructions"

    expect(page).to have_current_path(user_confirmation_path)
    expected_message = format(ConfirmationsController::FLASH_MESSAGE,
                              email: SiteConfig.email_addresses[:members])
    expect(page).to have_content(expected_message)
  end
end
