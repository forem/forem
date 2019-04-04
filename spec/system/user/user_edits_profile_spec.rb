# require "rails_helper"

# RSpec.describe "User edits their profile", type: :system, js: true do
#   let(:user) { create(:user, saw_onboarding: true) }

#   before do
#     sign_in user
#   end

#   describe "via their profile page" do
#     it "clicks on the edit profile button" do
#       visit "/#{user.username}"
#       find(:xpath, "//button[@id='user-follow-butt']").click
#       expect(page).to have_current_path("/settings")
#     end
#   end

#   describe "via visiting /settings" do
#     it "goes to /settings" do
#       visit "/settings"
#       expect(page).to have_current_path("/settings")
#     end
#   end

#   describe "via the navbar" do
#     it "clicks on the Settings button in the navbar" do
#       visit "/"
#       find(:xpath, "//button[@id='navigation-butt']").hover
#       find(:xpath, "//div[@id='loggedinmenu']/a[@href='/settings']").click
#       expect(page).to have_current_path("/settings")
#     end
#   end
# end
