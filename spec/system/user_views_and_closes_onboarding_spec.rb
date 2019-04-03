# require "rails_helper"

# describe "User views and closes onboarding", type: :system, js: true do
#   let(:tag) { create(:tag, name: "java") }

#   def sign_out
#     find("#navbar-menu-wrapper").hover.click_link(href: "/signout_confirm")
#     click_link(href: "/users/sign_out")
#   end

#   def click_sidebar_link
#     click_link("GITHUB")
#   end

#   def sign_up_or_in(provider = "twitter")
#     find("#navbar-menu-wrapper").hover.click_link(href: "/users/auth/#{provider}?state=navbar_basic")
#   end

#   def sign_up_and_close_onboarding
#     sign_up_or_in
#     button = find(".close-button")
#     button.click
#   end

#   before do
#     tag
#     visit "/"
#   end

#   describe "sign up via navbar, notifications, and sidebar goes to onboarding" do
#     describe "via navbar" do
#       xit "with Twitter" do
#         sign_up_or_in("twitter")
#         expect(find(".global-modal-inner")).to have_content("WELCOME!")
#       end

#       xit "with GitHub" do
#         sign_up_or_in("github")
#         expect(find(".global-modal-inner")).to have_content("WELCOME!")
#       end
#     end

#     describe "via notifications" do
#       it "with Twitter" do
#         click_link(href: "/notifications")
#         click_link("Twitter")
#         expect(find(".global-modal-inner")).to have_content("WELCOME!")
#       end

#       it "with GitHub" do
#         click_link(href: "/notifications")
#         click_link("GitHub")
#         expect(find(".global-modal-inner")).to have_content("WELCOME!")
#       end
#     end

#     describe "via sidebar" do
#       it "with Twitter" do
#         click_link("TWITTER")
#         expect(find(".global-modal-inner")).to have_content("WELCOME!")
#       end

#       it "with GitHub" do
#         click_link("GITHUB")
#         expect(find(".global-modal-inner")).to have_content("WELCOME!")
#       end
#     end
#   end

#   describe "via in-feed CTA" do
#     before do
#       5.times { create(:article, featured: true) }
#       visit "/"
#     end

#     it "with Twitter" do
#       # in_feed_link = find_link(href: "/users/auth/twitter?callback_url=https://dev.to/users/auth/twitter/callback")
#       # in_feed_link.click
#       # expect(find(".global-modal-inner")).to have_content("WELCOME!")
#     end

#     xit "with GitHub" do
#       in_feed_link = find_link(href: "/users/auth/github?state=in-feed-cta")
#       in_feed_link.click
#       expect(find(".global-modal-inner")).to have_content("WELCOME!")
#     end
#   end

#   describe "onboarding state does not reappear after closing or completing" do
#     xit "onboarding closes properly" do
#       sign_up_and_close_onboarding
#       expect(page).not_to have_selector(".close-button")
#     end

#     xit "onboarding stays closed after closing" do
#       sign_up_and_close_onboarding
#       sign_out
#       sign_up_or_in
#       expect(page).not_to have_selector(".global-modal-inner")
#     end

#     xit "onboarding stays closed after completing" do
#       sign_up_or_in
#       3.times { find(".next_button").click }
#       sign_out
#       sign_up_or_in
#       expect(page).not_to have_selector(".global-modal-inner")
#     end
#   end
# end
# rubocop:enable Metrics/LineLength
