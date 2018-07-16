require "rails_helper"

feature "Seeing checklist on home page" do
  let(:user) { create(:user) }

  background do
    sign_in user
  end

  # scenario "user visits home page to see checklist seen", js: true do
  #   visit "/"
  #   page.should have_css("#sidebar-additional.showing")
  # end
end