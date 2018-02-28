# require "rails_helper"
# require 'stripe_mock'

# feature "User adds a credit card" do
#   let(:stripe_helper) { StripeMock.create_test_helper }
#   let(:user) { create(:user) }
#   before do
#     StripeMock.start
#     Stripe::Plan.create(
#       :amount => 0,
#       :interval => "month",
#       :name => "Monthly Billing",
#       :currency => "usd",
#       :id => "monthly-billing"
#     )
#   end
#   after { StripeMock.stop }

#   background do
#     login_via_session_as user
#   end

#   scenario "User navigates to settings page and adds a card" do
#     visit "/settings/billing"
#     # find("#custom-stripe-button").click
#     expect(page).to have_text("+ Add Credit Card")
#     # click_button("+ Add Credit Card")
#     # find(:css, "input[@placeholder='Card Number']").set("4242424242424242")
#   end
# end
