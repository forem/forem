require "rails_helper"

RSpec.describe "Admin visits the overview page", type: :system, js: true do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    visit admin_path
  end

  it "tracks link clicks" do
    expect { click_link("Invite people") }.to change { Ahoy::Event.count }.by 1
  end
end
