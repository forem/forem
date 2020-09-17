require "rails_helper"

RSpec.describe "Admin dashboard is presented", type: :system do
  let(:admin) { build(:user, :super_admin) }
  let(:user) { build_stubbed(:user) }

  before { Bullet.raise = false }

  after { Bullet.raise = true }

  it "loads the admin dashboard articles view", js: true do
    sign_in admin
    visit "/resource_admin"
    expect(page).to have_content("Articles")
  end

  it "loads the admin dashboard podcasts view", js: true do
    sign_in admin
    visit "/resource_admin/podcasts"
    expect(page).to have_content("Podcast Episodes")
  end

  it "fails to load admin view for unauthorized users" do
    expect { visit "/resource_admin" }.to raise_error(Pundit::NotAuthorizedError)
    expect { visit "/resource_admin/podcasts" }.to raise_error(Pundit::NotAuthorizedError)
  end
end
