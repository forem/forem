require "rails_helper"

RSpec.describe "User index", type: :system, stub_elasticsearch: true do
  let!(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let!(:other_article) { create(:article) }
  let!(:comment) { create(:comment, user: user, commentable: other_article) }
  let!(:comment2) { create(:comment, user: user, commentable: other_article) }
  let(:organization) { create(:organization) }

  context "when user is unauthorized" do
    context "when 1 article" do
      before do
        Timecop.freeze
        visit "/#{user.username}"
      end

      after { Timecop.return }

      it "shows all proper elements", :aggregate_failures, js: true do
        shows_header
        shows_title
        shows_articles
        shows_comments
        shows_comment_timestamp
        shows_last_comments
      end

      def shows_header
        within("h1") { expect(page).to have_content(user.name) }
        within(".profile-header__actions") do
          expect(page).to have_button("Follow")
        end
      end

      def shows_title
        expect(page).to have_title("#{user.name} - #{SiteConfig.community_name}")
      end

      def shows_articles
        within(".crayons-story") do
          expect(page).to have_content(article.title)
          expect(page).not_to have_content(other_article.title)
        end
      end

      def shows_comments
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

      def shows_comment_timestamp
        within("#substories .profile-comment-card .profile-comment-row:first-of-type") do
          ts = comment.decorate.published_timestamp
          timestamp_selector = ".comment-date time[datetime='#{ts}']"
          expect(page).to have_selector(timestamp_selector)
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
      Capybara.current_session.driver.browser.manage.window.resize_to(1920, 1080)
      expect(page).to have_css(".spec-org-titles", text: "Organizations")
    end
  end

  context "when visiting own profile" do
    before do
      sign_in user
      visit "/#{user.username}"
    end

    it "shows all proper elements", :aggregate_failures, js: true do
      shows_header
      shows_articles
      shows_comments
      shows_last_comments
    end

    def shows_header
      within("h1") { expect(page).to have_content(user.name) }
      within(".profile-header__actions") do
        expect(page).to have_button("Edit profile")
      end
    end

    def shows_articles
      within(".crayons-story") do
        expect(page).to have_content(article.title)
        expect(page).not_to have_content(other_article.title)
      end
    end

    def shows_comments
      within("#substories div.profile-comment-card") do
        expect(page).to have_content("Recent comments")
        expect(page).to have_link(nil, href: comment.path)
      end
    end
  end

  def shows_last_comments
    stub_const("CommentsHelper::MAX_COMMENTS_TO_RENDER", 1)
    visit "/#{user.username}"
    within("#substories .profile-comment-card .pt-3 .fs-base") do
      expect(page).to have_content("View last 1 Comment")
    end
  end
end
