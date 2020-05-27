require "rails_helper"

RSpec.describe "Admin dashboard is presented", type: :system do
  let(:admin) { build(:user, :super_admin) }
  let(:user) { build_stubbed(:user) }

  before { Bullet.raise = false }

  after { Bullet.raise = true }

  xit "loads the admin dashboard articles view", js: true, percy: true do
    sign_in admin
    visxit "/admin"
    Percy.snapshot(page, name: "Admin dashboard: renders articles")
    expect(page).to have_content("Articles")
  end

  xit "loads the admin dashboard podcasts view", js: true, percy: true do
    sign_in admin
    visxit "/admin/podcasts"
    Percy.snapshot(page, name: "Admin dashboard: renders podcasts")
    expect(page).to have_content("Podcast Episodes")
  end

  xit "fails to load admin view for unauthorized users" do
    expect { visxit "/admin" }.to raise_error(Pundit::NotAuthorizedError)
    expect { visxit "/admin/podcasts" }.to raise_error(Pundit::NotAuthorizedError)
  end
end
