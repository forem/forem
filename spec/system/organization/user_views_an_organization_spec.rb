require "rails_helper"

RSpec.describe "Organization index" do
  let!(:org_user) { create(:user, :org_member) }
  let(:organization) { org_user.organizations.first }

  context "when user does not follow organization" do
    context "when 2 articles" do
      before do
        create_list(:article, 2, organization: organization)
        visit "/#{organization.slug}"
      end

      it "shows the header", js: true do
        within("h1.crayons-title") { expect(page).to have_content(organization.name) }
        within("div.profile-header__actions") do
          expect(page).to have_button(I18n.t("core.follow"))
        end
      end

      it "shows articles" do
        expect(page).to have_selector("div.crayons-story", count: 2)
      end

      it "shows the sidebar" do
        within("#sidebar-left") do
          expect(page).to have_content("Meet the team")
          expect(page).to have_link(nil, href: org_user.path)
        end
      end

      it "shows the right amount of articles in sidebar" do
        expect(page).to have_content("2 posts published")
      end

      it "shows the proper title tag" do
        expect(page).to have_title("#{organization.name} - #{Settings::Community.community_name}")
      end
    end

    context "when more articles" do
      it "visits ok", js: true do
        create_list(:article, 3, organization: organization)
        visit "/#{organization.slug}"
      end
    end

    context "when more than 8 articles" do
      before do
        create_list(:article, 9, organization: organization)
        visit "/#{organization.slug}"
      end

      it "tells the user the correct amount of posts published" do
        expect(page).to have_content("9 posts published")
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

      within(".profile-header__actions") do
        expect(page).to have_button(I18n.t("core.following"))
      end
    end
  end
end
