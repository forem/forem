require "rails_helper"

RSpec.feature "Looking For Work" do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, name: "hiring") }

  before do
    login_as(user)
  end

  scenario "User selects looking for work and autofollows hiring tag" do
    tag
    visit "/settings"
    page.check "Looking for work"
    click_button("submit")
    Delayed::Worker.new.work_off
    expect(user.follows.count).to eq(1)
  end
end
