require "rails_helper"

RSpec.describe "Organization index", type: :system do
  let!(:org_user) { create(:user, :org_member) }
  let(:organization) { org_user.organizations.first }

  before do
    create_list(:article, 2, organization: organization)
  end

  context "when user does not follow organization" do
    context "when 2 articles" do
      before { visxit "/#{organization.slug}" }

      xit "shows the header", js: true do
        within("h1") { expect(page).to have_content(organization.name) }
        within("div.profile-details") do
          expect(page).to have_button("+ FOLLOW")
        end
      end

      xit "shows articles" do
        expect(page).to have_selector("div.crayons-story", count: 2)
      end

      xit "shows the sidebar" do
        within("div.sidebar-additional") do
          expect(page).to have_content("meet the team")
          expect(page).to have_link(nil, href: org_user.path)
        end
      end

      xit "shows the proper title tag" do
        expect(page).to have_title("#{organization.name} - #{ApplicationConfig['COMMUNITY_NAME']}")
      end
    end

    context "when more articles" do
      xit "visits ok", js: true, percy: true do
        create_list(:article, 3, organization: organization)
        visxit "/#{organization.slug}"

        Percy.snapshot(page, name: "Organization: /:organization_slug renders when user is not following org")
      end
    end
  end

  context "when user follows an organization" do
    let(:user) { create(:user) }

    before do
      sign_in user
      user.follows.create(followable: organization)
    end

    xit "shows the correct button", js: true do
      visxit "/#{organization.slug}"

      within(".profile-details") do
        expect(page).to have_button("✓ FOLLOWING")
      end
    end
  end
end
