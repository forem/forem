require "rails_helper"

RSpec.describe "Admin bans user", type: :system do
  let(:admin)  { create(:user, :super_admin) }
  let(:user)   { create(:user) }

  before do
    sign_in admin
    visit admin_user_path(user.id)
  end

  def suspend_user
    visit admin_user_path(user.id)
    select("Suspend", from: "user_user_status")
    fill_in("user_note_for_current_role", with: "something")
    click_button("Add")
    expect(page).to have_content("User has been updated")
  end

  def warn_user
    visit admin_user_path(user.id)
    select("Warn", from: "user_user_status")
    fill_in("user_note_for_current_role", with: "something")
    click_button("Add")
    expect(page).to have_content("User has been updated")
  end

  def add_tag_moderator_role
    tag = create(:tag)
    user.add_role(:tag_moderator, tag)
  end

  def unsuspend_user
    visit admin_user_path(user.id)
    select("Regular Member", from: "user_user_status")
    fill_in("user_note_for_current_role", with: "good user")
    click_button("Add")
    expect(page).to have_content("User has been updated")
  end

  it "checks that the user is warned, has a note, and privileges are removed" do
    user.add_role(:trusted)
    add_tag_moderator_role
    warn_user

    expect(user.warned?).to be(true)
    expect(Note.last.reason).to eq "Warn"
    expect(user.tag_moderator?).to be(false)
  end

  # to-do: add spec for invalid bans
  it "checks that the user is suspended and has note" do
    suspend_user
    expect(user.suspended?).to be(true)
    expect(Note.last.reason).to eq "Suspend"
  end

  it "removes other roles if user is suspended" do
    user.add_role(:trusted)
    add_tag_moderator_role
    suspend_user

    expect(user.suspended?).to be(true)
    expect(user.trusted?).to be(false)
    expect(user.warned?).to be(false)
    expect(user.tag_moderator?).to be(false)
  end

  it "unsuspends user" do
    user.add_role(:suspended)
    unsuspend_user

    expect(user.suspended?).to be(false)
  end
end
