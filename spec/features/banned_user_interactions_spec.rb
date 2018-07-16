require "rails_helper"

feature "Banned user" do
  let(:banned_user)   { create(:user, :banned) }

  scenario "tries to create an article" do
    sign_in banned_user
    expect { visit "/new" }.to raise_error("BANNED")
  end
end
