require "rails_helper"

RSpec.describe "User edits their UX settings", type: :system do
  let(:user) { create(:user, saw_onboarding: true) }

  before do
    sign_in user
    visit "/settings/ux"
  end

  describe "visiting /settings/ux" do
    it "makes the 'Save Button' footer sticky once a theme is selected", js: true do
      expect(page).not_to have_css(".sticky")

      choose "Ten X Hacker Theme"

      expect(page).to have_css(".sticky")
    end
  end
end
