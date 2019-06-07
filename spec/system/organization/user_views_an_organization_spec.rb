require "rails_helper"

RSpec.describe "Organization index", type: :system do
  let!(:org_user) { create(:user, :org_member) }
  let(:organization) { org_user.organizations.first }

  before do
    create_list(:article, 2, organization: organization)
  end

  context "when user is unauthorized" do
    context "when 2 articles" do
      before { visit "/#{organization.slug}" }

      it "shows the header", js: true do
        within("h1") { expect(page).to have_content(organization.name) }
        within("div.profile-details") do
          expect(page).to have_button("+ FOLLOW")
        end
      end

      it "shows articles" do
        expect(page).to have_selector("div.single-article", count: 2)
      end

      it "shows the sidebar" do
        within("div.sidebar-additional") do
          expect(page).to have_content("meet the team")
          expect(page).to have_link(nil, href: org_user.path)
        end
      end

      it "shows the proper title tag" do
        expect(page).to have_title("#{organization.name} - #{ApplicationConfig['COMMUNITY_NAME']} Community 👩‍💻👨‍💻")
      end
    end

    context "when more articles" do
      it "visits ok" do
        create_list(:article, 3, organization: organization)
        visit "/#{organization.slug}"
      end
    end
  end

  context "when user follows an organization" do
    let(:user) { create(:user) }

    before do
      sign_in user
      user.follows.create(followable: organization)
    end

    it "shows the correct button", js: true do
      visit "/#{organization.slug}"
      within(".profile-details") do
        expect(page).to have_button("✓ FOLLOWING")
      end
    end
  end
end
