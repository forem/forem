require "rails_helper"

RSpec.describe "Admin visits overview page", js: true do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    visit admin_path
  end

  it "has activity statistics" do
    expect(page.body).to include "Activity Statistics"
  end

  it "displays stats cards" do
    expect(page.body).to include "Published Posts"
    expect(page.body).to include "Comments"
    expect(page.body).to include "Public Reactions"
    expect(page.body).to include "New Users"
  end
end
