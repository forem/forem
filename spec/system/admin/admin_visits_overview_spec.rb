require "rails_helper"

RSpec.describe "Admin visits overview page", js: true do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    visit admin_path
  end

  it "has analytics" do
    expect(page.body).to include "Analytics and trends"
  end
end
