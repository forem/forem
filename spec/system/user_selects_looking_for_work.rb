require "rails_helper"

RSpec.describe "Looking For Work" do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, name: "hiring") }

  before do
    login_as(user)
    tag
  end

  it "user selects looking for work and autofollows hiring tag" do
    visit "/settings"
    page.check "Looking for work"
    click_button("submit")
    expect(user.follows.count).to eq(1)
  end
end
