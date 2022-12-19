require "rails_helper"

RSpec.describe "User index", type: :system do
  let!(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let!(:other_article) { create(:article) }
  let!(:comment) { create(:comment, user: user, commentable: other_article) }
  let!(:comment2) { create(:comment, user: user, commentable: other_article) }
  let(:organization) { create(:organization) }

  context "when user is unauthorized" do
    before do
      visit "/#{user.username}"
    end

    context "when 1 article" do
      it "shows header", :aggregate_failures, js: true do
        within("h1") { expect(page).to have_content(user.name) }
        within(".profile-header__actions") do
          expect(page).to have_button(I18n.t("core.follow"))
        end
      end

      it "shows title", :aggregate_failures, js: true do
        expect(page).to have_title("#{user.name} - #{Settings::Community.community_name}")
      end

      it "shows articles", :aggregate_failures, js: true do
        within(".crayons-story") do
          expect(page).to have_content(article.title)
          expect(page).not_to have_content(other_article.title)
        end
      end

      it "shows comments locked cta", :aggregate_failures, js: true do
        within("#comments-locked-cta") do
          expect(page).to have_content("Want to connect with #{user.name}?")
        end
      end

      it "hides comments", :aggregate_failures, js: true do
        within("#substories") do
          expect(page).not_to have_content("Recent comments")
        end
      end
    end
  end

  context "when user has an organization membership" do
    before do
      user.organization_memberships.create(organization: organization, type_of_user: "member")
      visit "/#{user.username}"
    end

    it "shows organizations", js: true do
      expect(page).to have_css(".spec-org-titles", text: "Organizations")
    end
  end

  context "when user is logged in" do
    before do
      sign_in user
      visit "/#{user.username}"
    end

    context "when user visits a profile" do
      it "shows_comments", :aggregate_failures, js: true do
        within("#substories div.profile-comment-card") do
          expect(page).to have_content("Recent comments")
          expect(page).to have_link(nil, href: comment.path)
          expect(page).to have_link(nil, href: comment2.path)
        end

        within("#substories") do
          expect(page).to have_selector(".profile-comment-card", count: 1)
        end

        within("#substories .profile-comment-card .profile-comment-row:first-of-type") do
          comment_date = comment.readable_publish_date.gsub("  ", " ")
          expect(page).to have_selector(".comment-date", text: comment_date)
        end
      end

      it "shows comment timestamp", :aggregate_failures, js: true do
        within("#substories .profile-comment-card .profile-comment-row:first-of-type") do
          iso8601_date_time = /^((\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z)$/
          timestamp = page.find(".comment-date time")[:datetime]
          expect(timestamp).to match(iso8601_date_time)
        end
      end
    end
  end

  context "when visiting own profile" do
    before do
      sign_in user
      visit "/#{user.username}"
    end

    context "when user is logged in" do
      it "shows_header", :aggregate_failures, js: true do
        within("h1") { expect(page).to have_content(user.name) }
        within(".profile-header__actions") do
          expect(page).to have_button(I18n.t("core.edit_profile"))
        end
      end

      it "shows articles", :aggregate_failures, js: true do
        within(".crayons-story") do
          expect(page).to have_content(article.title)
          expect(page).not_to have_content(other_article.title)
        end
      end

      it "shows comments", :aggregate_failures, js: true do
        within("#substories div.profile-comment-card") do
          expect(page).to have_content("Recent comments")
          expect(page).to have_link(nil, href: comment.path)
        end
      end

      it "shows comment timestamp", :aggregate_failures, js: true do
        within("#substories .profile-comment-card .profile-comment-row:first-of-type") do
          iso8601_date_time = /^((\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z)$/
          timestamp = page.find(".comment-date time")[:datetime]
          expect(timestamp).to match(iso8601_date_time)
        end
      end

      it "hides comments locked cta", :aggregate_failures, js: true do
        within("#substories") do
          expect(page).not_to have_content("Want to connect with #{user.name}?")
        end
      end
    end

    it "shows last comments", :aggregate_failures, js: true do
      stub_const("CommentsHelper::MAX_COMMENTS_TO_RENDER", 1)
      visit "/#{user.username}"
      within("#substories .profile-comment-card .pt-3 .fs-base") do
        expect(page).to have_content("View last 1 Comment")
      end
    end
  end
end
