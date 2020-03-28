require "rails_helper"

RSpec.describe "Admin dashboard is presented", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }

  before { Bullet.raise = false }

  after { Bullet.raise = true }

  it "loads the admin dashboard view" do
    sign_in admin
    visit "/admin"
    expect(page).to have_content("Articles")

    visit "/admin/podcasts"
    expect(page).to have_content("Podcast Episodes")
  end

  it "fails to load admin view for unauthorized users" do
    expect { visit "/admin" }.to raise_error(Pundit::NotAuthorizedError)
    expect { visit "/admin/podcasts" }.to raise_error(Pundit::NotAuthorizedError)
  end
end
