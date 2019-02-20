require "rails_helper"

describe "Admin bans user" do
  let(:admin)  { create(:user, :super_admin) }
  let(:user)   { create(:user) }

  before do
    sign_in admin
    visit "/internal/users/#{user.id}"
  end

  def ban_user
    check("user_ban_user")
    fill_in("user_note_for_current_role", with: "something")
    click_button("Update User Status")
  end

  def unban_user
    visit "/internal/users/#{user.id}"
    uncheck("user_ban_user")
    click_button("Update User Status")
  end

  def warn_user
    check("user_warn_user")
    fill_in("user_note_for_current_role", with: "something")
    click_button("Update User Status")
  end

  def add_tag_moderator_role
    tag = FactoryBot.create(:tag)
    user.add_role :tag_moderator, tag
  end

  describe "valid warning" do
    it "checks that the user is warned, has a reason for warning, and privileges are removed" do
      user.add_role :trusted
      add_tag_moderator_role
      warn_user
      expect(user.warned).to eq(true)
      expect(user.reason_for_warning).to eq "something"
      expect(user.has_role?(:tag_moderator)).to eq(false)
    end
  end

  # to-do: add spec for invalid bans

  describe "valid ban" do
    it "checks that the user is banned and has a reason for ban" do
      ban_user
      expect(user.banned).to eq(true)
      expect(user.reason_for_ban).to eq "something"
    end

    it "removes other roles if user is banned" do
      user.add_role :trusted
      user.add_role :video_permission
      add_tag_moderator_role
      ban_user
      expect(user.banned).to eq(true)
      expect(user.trusted).to eq(false)
      expect(user.warned).to eq(false)
      expect(user.has_role?(:video_permission)).to eq(false)
      expect(user.has_role?(:tag_modertor)).to eq(false)
    end
  end

  describe "valid unban" do
    it "allows a previously banned user to be unbanned" do
      user.add_role :banned
      unban_user
      expect(user.banned).to eq(false)
    end
  end
end
