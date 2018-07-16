require "rails_helper"

feature "Admin bans user" do
  let(:admin)  { create(:user, :super_admin) }
  let(:user)   { create(:user) }

  background do
    sign_in admin
  end

  before do
    visit "/admin/users/#{user.id}/edit"
  end

  def ban_user
    check("Banned")
    fill_in("Reason for ban", with: "something")
    click_button("Update User")
  end

  def unban_user
    visit "/admin/users/#{user.id}/edit"
    uncheck("Banned")
    click_button("Update User")
  end

  describe "invalid bans" do
    scenario "fails to ban if no note is left" do
      check("Banned")
      click_button("Update User")
      expect(page).to have_content(/Reason for ban can't be blank if banned is checked/i)
    end

    scenario "fails to ban if a reason for ban is left but ban box is not checked" do
      fill_in("Reason for ban", with: "something")
      click_button("Update User")
      expect(page).to have_content("Banned was not checked but had the reason filled out")
    end
  end

  describe "valid ban" do
    scenario "checks that the user is banned and has a reason for ban" do
      ban_user
      expect(user.banned).to eq(true)
      expect(user.reason_for_ban).to eq "something"
    end
  end

  describe "valid unban" do
    scenario "allows a previously banned user to be unbanned" do
      ban_user
      unban_user
      expect(user.banned).to eq(false)
      expect(user.reason_for_ban).to eq "something"
    end
  end
end
