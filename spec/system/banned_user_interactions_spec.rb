require "rails_helper"

RSpec.describe "Suspended user", type: :system do
  let(:suspended_user)   { create(:user, :suspended) }

  it "tries to create an article" do
    sign_in suspended_user
    expect { visit "/new" }.to raise_error(SuspendedError)
  end
end
