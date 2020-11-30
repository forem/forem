require "rails_helper"

RSpec.describe ProfileValidator, type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
    visit "/settings"
  end

  describe "simple ProfileValidator checks" do
    it "saves the profile with proper length summary" do
      fill_in "profile[summary]", with: "short summary"
      click_button "Save"

      expect(page).to have_text("Your profile has been updated")
    end

    it "fails to save the profile when summary is too long" do
      fill_in "profile[summary]", with: "very long summary " * 100
      click_button "Save"

      expect(page).to have_text("Error: Summary is too long")
    end
  end

  describe "edge case with custom (admin created) fields when empty" do
    it "saves the profile properly when custom fields are left empty" do
      create(:profile_field, label: "new field")

      expect do
        fill_in "profile[summary]", with: "first summary edit"
        click_button "Save"

        fill_in "profile[summary]", with: "second summary edit"
        click_button "Save"

        fill_in "profile[summary]", with: "third summary edit"
        click_button "Save"
      end.not_to raise_error
    end
  end
end
