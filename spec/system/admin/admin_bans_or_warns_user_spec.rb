require "rails_helper"

RSpec.describe "Admin bans user", type: :system do
  let(:admin)  { create(:user, :super_admin) }
  let(:user)   { create(:user) }

  before do
    sign_in admin
    visit edit_admin_user_path(user.id)
  end

  def suspend_user
    visit edit_admin_user_path(user.id)
    select("Suspend", from: "user_user_status")
    fill_in("user_note_for_current_role", with: "something")
    click_button("Update User Status")
    expect(page).to have_content("User has been updated")
  end

  def warn_user
    visit edit_admin_user_path(user.id)
    select("Warn", from: "user_user_status")
    fill_in("user_note_for_current_role", with: "something")
    click_button("Update User Status")
    expect(page).to have_content("User has been updated")
  end

  def add_tag_moderator_role
    tag = FactoryBot.create(:tag)
    user.add_role(:tag_moderator, tag)
  end

  def unsuspend_user
    visit edit_admin_user_path(user.id)
    select("Regular Member", from: "user_user_status")
    fill_in("user_note_for_current_role", with: "good user")
    click_button("Update User Status")
    expect(page).to have_content("User has been updated")
  end

  it "checks that the user is warned, has a note, and privileges are removed" do
    user.add_role(:trusted)
    add_tag_moderator_role
    warn_user

    expect(user.warned).to eq(true)
    expect(Note.last.reason).to eq "Warn"
    expect(user.has_role?(:tag_moderator)).to eq(false)
  end

  # to-do: add spec for invalid bans
  it "checks that the user is suspended and has note" do
    suspend_user
    expect(user.suspended?).to eq(true)
    expect(Note.last.reason).to eq "Suspend"
  end

  it "removes other roles if user is suspended" do
    user.add_role(:trusted)
    add_tag_moderator_role
    suspend_user

    expect(user.suspended?).to eq(true)
    expect(user.trusted).to eq(false)
    expect(user.warned).to eq(false)
    expect(user.has_role?(:tag_modertor)).to eq(false)
  end

  it "unsuspends user" do
    user.add_role(:suspended)
    unsuspend_user

    expect(user.has_role?(:suspended)).to eq(false)
  end
end
