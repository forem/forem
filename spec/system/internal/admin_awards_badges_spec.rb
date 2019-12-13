require "rails_helper"

RSpec.describe "Admin awards badges", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  def submit_form
    find(:xpath, "//option[contains(text(), \"#{Badge.last.title}\")]").select_option
    fill_in "usernames", with: "#{user.username}, #{user2.username}"
    fill_in "message_markdown", with: "He who controls the spice controls the universe."
    click_on "Award Badges"
  end

  before do
    create_list :badge, 5
    sign_in admin
    visit "/internal/badges"
  end

  it "loads the view" do
    expect(page).to have_content("Badges")
  end

  it "lists the badges" do
    Badge.all.each do |b|
      expect(page).to have_content(b.title)
    end
  end

  it "awards badges" do
    expect { submit_form }.to change { user.badges.count }.by(1).and change { user2.badges.count }.by(1)
    expect(page).to have_content("BadgeRewarder task ran!")
  end
end
