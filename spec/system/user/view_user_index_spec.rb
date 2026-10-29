require "rails_helper"

RSpec.describe "User index" do
  let!(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let!(:other_article) { create(:article) }
  let!(:comment) { create(:comment, user: user, commentable: other_article, created_at: 2.days.ago) }
  let!(:comment2) { create(:comment, user: user, commentable: other_article, created_at: 1.day.ago) }
  let(:organization) { create(:organization) }

  context "when user is unauthorized" do
    before do
      visit "/#{user.username}"
    end

    context "when 1 article" do
      it "shows header, title, articles, and locked comments cta while hiding comments", :aggregate_failures do
        within("h1.crayons-title") { expect(page).to have_content(user.name) }
        within(".profile-header__actions") do
          expect(page).to have_button(I18n.t("core.follow"))
        end
        expect(page).to have_title("#{user.name} - #{Settings::Community.community_name}")
        within(".crayons-story") do
          expect(page).to have_content(article.title)
          expect(page).to have_no_content(other_article.title)
        end
        within("#comments-locked-cta") do
          expect(page).to have_content("Want to connect with #{user.name}?")
        end
        within("#substories") do
          expect(page).to have_no_content("Recent comments")
        end
      end
    end
  end

  context "when user is logged in" do
    before do
      sign_in user
    end

    context "when user visits a profile" do
      it "shows comments and timestamps, header, articles, and hides locked cta", :aggregate_failures, :js do
        visit "/#{user.username}"
        expect(page).to have_css("body[data-loaded='true']", wait: 30)

        within("h1.crayons-title") { expect(page).to have_content(user.name) }
        within(".profile-header__actions") do
          expect(page).to have_button(I18n.t("core.edit_profile"))
        end
        within(".crayons-story") do
          expect(page).to have_content(article.title)
          expect(page).to have_no_content(other_article.title)
        end
        within("#substories div.profile-comment-card") do
          expect(page).to have_content("Recent comments")
          expect(page).to have_link(nil, href: comment.path)
          expect(page).to have_link(nil, href: comment2.path)
        end

        within("#substories") do
          expect(page).to have_css(".profile-comment-card", count: 1)
          expect(page).to have_no_content("Want to connect with #{user.name}?")
        end

        within("#substories .profile-comment-card .profile-comment-row:first-of-type") do
          possible_dates = [
            comment2.readable_publish_date,
            I18n.l(comment2.created_at.utc, format: :short),
            I18n.l(Time.current, format: :short),
            I18n.l(Time.current.utc, format: :short),
            I18n.l(2.days.ago, format: :short),
            I18n.l(2.days.ago.utc, format: :short),
          ].map { |d| d.gsub("  ", " ") }.uniq
          expect(page).to have_css(".comment-date", text: Regexp.union(possible_dates))

          iso8601_date_time = /^((\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z)$/
          timestamp = page.find(".comment-date time")[:datetime]
          expect(timestamp).to match(iso8601_date_time)
        end
      end
    end

    it "shows organizations and last comments link when truncated", :aggregate_failures do
      user.organization_memberships.create(organization: organization, type_of_user: "member")
      stub_const("CommentsHelper::MAX_COMMENTS_TO_RENDER", 1)
      visit "/#{user.username}"
      expect(page).to have_css(".spec-org-titles", text: "Organizations")
      within("#substories .profile-comment-card .pt-3 .fs-base") do
        expect(page).to have_content("View recent comments")
      end
    end
  end
end
