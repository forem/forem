require "rails_helper"

describe "Banned user" do
  let(:banned_user)   { create(:user, :banned) }

  it "tries to create an article" do
    sign_in banned_user
    expect { visit "/new" }.to raise_error("BANNED")
  end
end
