require "rails_helper"

RSpec.describe "User edits their Customization settings", type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user

    visit user_settings_path(:customization)
  end

  describe "visiting Customization section" do
    it "makes the 'Save Button' footer sticky once a theme is selected", js: true do
      expect(page).not_to have_css(".sticky")

      choose("Ten X Hacker Theme")

      expect(page).to have_css(".sticky")
    end
  end
end
