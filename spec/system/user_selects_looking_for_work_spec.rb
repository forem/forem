require "rails_helper"

RSpec.describe "Looking For Work" do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, name: "hiring") }

  before do
    sign_in(user)
    tag
  end

  it "user selects looking for work and autofollows hiring tag" do
    visit "/settings"
    page.check "Looking for work"
    run_background_jobs_immediately do
      click_button("SUBMIT")
      expect(user.follows.count).to eq(1)
    end
  end
end
