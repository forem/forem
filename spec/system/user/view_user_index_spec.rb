require "rails_helper"

RSpec.describe "User index", type: :system, stub_elasticsearch: true do
  let!(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let!(:other_article) { create(:article) }
  let!(:comment) { create(:comment, user: user, commentable: other_article) }
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
        within("#substories div.index-comments") do
          expect(page).to have_content("Recent Comments")
          expect(page).to have_link(nil, href: comment.path)
        end

        within("#substories") do
          expect(page).to have_selector(".index-comments", count: 1)
        end

        within("#substories .index-comments .single-comment") do
          comment_date = comment.readable_publish_date.gsub("  ", " ")
          expect(page).to have_selector(".comment-date", text: comment_date)
        end
      end

      def shows_comment_timestamp
        within("#substories .index-comments .single-comment") do
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
      expect(page).to have_css("#sidebar-wrapper-right h4", text: "organizations")
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
      within("#substories div.index-comments") do
        expect(page).to have_content("Recent Comments")
        expect(page).to have_link(nil, href: comment.path)
      end
    end
  end
end
