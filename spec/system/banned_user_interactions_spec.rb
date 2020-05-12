require "rails_helper"

RSpec.describe "Banned user", type: :system do
  let(:banned_user)   { create(:user, :banned) }

  it "tries to create an article" do
    sign_in banned_user
    expect { visit "/new" }.to raise_error("SUSPENDED")
  end
end
