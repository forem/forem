require "rails_helper"

RSpec.describe "Organization index" do
  let(:org_user) { create(:user, :without_profile, :org_member, profile_image: nil) }
  let(:organization) { org_user.organizations.first }

  context "when user does not follow organization" do
    context "when 2 articles" do
      before do
        create_list(:article, 2, organization: organization, user: org_user, with_tags: false)
        visit "/#{organization.slug}"
      end

      it "shows the header, articles, sidebar, post count, and title tag", :aggregate_failures do
        within("h1.crayons-title") { expect(page).to have_content(organization.name) }
        within("div.org-header-actions") do
          expect(page).to have_button(I18n.t("core.follow"))
        end
        expect(page).to have_css("div.crayons-story", count: 2)
        within("#sidebar-left") do
          expect(page).to have_content("Meet the team")
          expect(page).to have_link(nil, href: org_user.path)
        end
        expect(page).to have_content("2 posts published")
        expect(page).to have_title("#{organization.name} - #{Settings::Community.community_name}")
      end
    end

    context "when more than 8 articles" do
      before do
        create_list(:article, 9, organization: organization, user: org_user, with_tags: false, with_main_image: false)
        visit "/#{organization.slug}"
      end

      it "tells the user the correct amount of posts published" do
        expect(page).to have_content("9 posts published")
      end
    end
  end

  context "when user follows an organization" do
    let(:user) { create(:user, :without_profile, profile_image: nil) }

    before do
      sign_in user
      user.follows.create(followable: organization)
    end

    it "shows the correct button after follow state loads", :js do
      visit "/#{organization.slug}"

      within(".org-header-actions") do
        expect(page).to have_button(I18n.t("core.following"))
      end
    end
  end

  context "when there are multiple members in the organization within a limit" do
    let(:many_members_org) { create(:organization) }

    let(:some_badges_member) { create(:user, :without_profile, profile_image: nil, badge_achievements_count: 15) }
    let(:many_badges_member) { create(:user, :without_profile, profile_image: nil, badge_achievements_count: 50) }
    let(:no_badges_member) { create(:user, :without_profile, profile_image: nil, badge_achievements_count: 0) }
    let(:few_badges_member) { create(:user, :without_profile, profile_image: nil, badge_achievements_count: 5) }
    let(:org_members) { [some_badges_member, many_badges_member, no_badges_member, few_badges_member] }

    before do
      org_members.each { |user| create(:organization_membership, user: user, organization: many_members_org) }
      visit "/#{many_members_org.slug}"
    end

    def nth_avatar(user_position)
      ".org-sidebar-widget-user-pic:nth-child(#{user_position})"
    end

    it "shows the sidebar with users in descending badge count order without 'See All Members'", :aggregate_failures do
      within("#sidebar-left") do
        expect(page).to have_content("Meet the team")
        expect(page.find(nth_avatar(1))).to have_link(nil, href: many_badges_member.path)
        expect(page.find(nth_avatar(2))).to have_link(nil, href: some_badges_member.path)
        expect(page.find(nth_avatar(3))).to have_link(nil, href: few_badges_member.path)
        expect(page.find(nth_avatar(4))).to have_link(nil, href: no_badges_member.path)
        expect(page).to have_no_content("See All Members")
      end
    end
  end

  context "when there are more than 50 members in the organization" do
    let(:many_members_org) { create(:organization) }

    before do
      now = Time.current
      users = Array.new(55) do |i|
        { name: "Org Member #{i}", username: "org_member_#{i}", email: "org_member_#{i}@example.com",
          registered: true, badge_achievements_count: i + 1, created_at: now, updated_at: now }
      end
      user_ids = User.insert_all(users, returning: %i[id]).rows.flatten
      OrganizationMembership.insert_all(
        user_ids.map do |user_id|
          { user_id: user_id, organization_id: many_members_org.id, type_of_user: "member",
            created_at: now, updated_at: now }
        end,
      )
      visit "/#{many_members_org.slug}"
    end

    def nth_avatar(user_position)
      ".org-sidebar-widget-user-pic:nth-child(#{user_position})"
    end

    it "shows up to 50 users in the sidebar, 'See All Members' link, and all 55 on '/members'", :aggregate_failures do
      within("#sidebar-left") do
        expect(page).to have_content("Meet the team")

        (1..50).each do |i|
          expect(page).to have_css(nth_avatar(i))
        end

        expect(page).to have_no_css(nth_avatar(51))
      end

      within(".org-sidebar-widget") do
        expect(page).to have_content("See All Members")
      end

      visit "/#{many_members_org.slug}/members"
      within(".grid-cols-1") do
        expect(page).to have_css(".member-item", count: 55)
      end
    end
  end
end
