require "rails_helper"

describe "Tag index page (/tags)", type: :feature, js: true do
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }

  def match_checkmark(checkmark)
    # ✔ seems to appear in chrome
    # ✓ seems to appear headless chrome
    checkmark == "✔" || checkmark == "✓"
  end

  before { login_as(user) }

  context "when a tag is not already followed" do
    before do
      tag
      visit "/tags"
    end
  end  
end
