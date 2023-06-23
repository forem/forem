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

  context "when there are multiple members in the organization within a limit" do
    let(:many_members_org) { create(:organization) }

    let(:some_badges_member) { create(:user, badge_achievements_count: 15) }
    let(:many_badges_member) { create(:user, badge_achievements_count: 50) }
    let(:no_badges_member) { create(:user, badge_achievements_count: 0) }
    let(:few_badges_member) { create(:user, badge_achievements_count: 5) }
    let(:org_members) { [some_badges_member, many_badges_member, no_badges_member, few_badges_member] }

    before do
      org_members.each { |user| create(:organization_membership, user: user, organization: many_members_org) }
      visit "/#{many_members_org.slug}"
    end

    def nth_avatar(user_position)
      ".org-sidebar-widget-user-pic:nth-child(#{user_position})"
    end

    it "shows the sidebar with users listed in descending badge count order" do
      within("#sidebar-left") do
        expect(page).to have_content("Meet the team")
        expect(page.find(nth_avatar(1))).to have_link(nil, href: many_badges_member.path)
        expect(page.find(nth_avatar(2))).to have_link(nil, href: some_badges_member.path)
        expect(page.find(nth_avatar(3))).to have_link(nil, href: few_badges_member.path)
        expect(page.find(nth_avatar(4))).to have_link(nil, href: no_badges_member.path)
      end
    end

    it "does not show the 'See all members' link" do
      within("#sidebar-left") do
        expect(page).not_to have_content("See All Members")
      end
    end
  end

  context "when there are more than 50 members in the organization" do
    let(:many_members_org) { create(:organization) }

    before do
      55.times do
        user = create(:user, badge_achievements_count: rand(1..100))
        create(:organization_membership, user: user, organization: many_members_org)
      end
      visit "/#{many_members_org.slug}"
    end

    def nth_avatar(user_position)
      ".org-sidebar-widget-user-pic:nth-child(#{user_position})"
    end

    it "shows the sidebar till 50th user only" do
      within("#sidebar-left") do
        expect(page).to have_content("Meet the team")

        # This checks that first 50 users are available and 51st item is not.
        (1..50).each do |i|
          expect(page).to have_css(nth_avatar(i))
        end

        expect(page).not_to have_css(nth_avatar(51))
      end
    end

    it "shows the 'See All Members' link" do
      within(".org-sidebar-widget") do
        expect(page).to have_content("See All Members")
      end
    end

    it "displays the members on the '/members' page" do
      visit "/#{many_members_org.slug}/members"
      within(".grid-cols-1") do
        expect(page).to have_selector(".member-item", count: 55)
      end
    end
  end
end
