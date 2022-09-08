require "rails_helper"

RSpec.describe "Admin awards badges", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:badges) { Badge.pluck(:title) }

  def award_two_badges
    find(:xpath, "//option[contains(text(), \"#{badges.last}\")]").select_option
    fill_in "usernames", with: "#{user.username}, #{user2.username}"
    fill_in "message_markdown", with: "He who controls the spice controls the universe."
    click_on "Award Badges"
  end

  def award_no_badges
    fill_in "usernames", with: "#{user.username}, #{user2.username}"
    fill_in "message_markdown", with: "He who controls the spice controls the universe."
    click_on "Award Badges"
  end

  before do
    create_list :badge, 5
    sign_in admin
    visit admin_badge_achievements_award_badges_path
  end

  it "loads the view" do
    expect(page).to have_content("Badges")
  end

  it "lists the badges" do
    badges.each do |badge|
      expect(page).to have_content(badge)
    end
  end

  it "does not award badges if no badge is selected", js: true do
    expect do
      sidekiq_perform_enqueued_jobs { award_no_badges }
    end.not_to change { user.badges.count }

    expect(page).to have_content("Please choose a badge to award")
  end
end
