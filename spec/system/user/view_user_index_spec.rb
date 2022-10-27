require "rails_helper"

RSpec.describe "User index", type: :system do
  let!(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let!(:other_article) { create(:article) }
  let!(:comment) { create(:comment, user: user, commentable: other_article) }
  let(:organization) { create(:organization) }

  context "when user is unauthorized" do
    before do
      Timecop.freeze
      visit "/#{user.username}"
    end

    after { Timecop.return }

    context "when 1 article" do
      it "shows_header", :aggregate_failures, js: true do
        within("h1") { expect(page).to have_content(user.name) }
        within(".profile-header__actions") do
          expect(page).to have_button(I18n.t("core.follow"))
        end
      end

      it "shows_title", :aggregate_failures, js: true do
        expect(page).to have_title("#{user.name} - #{Settings::Community.community_name}")
      end

      it "shows_articles", :aggregate_failures, js: true do
        within(".crayons-story") do
          expect(page).to have_content(article.title)
          expect(page).not_to have_content(other_article.title)
        end
      end

      it "shows_comments_locked_cta", :aggregate_failures, js: true do
        within("#comments-locked-cta") do
          expect(page).to have_content("Want to connect with #{user.name}?")
        end
      end

      it "hides_comments", :aggregate_failures, js: true do
        within("#substories") do
          expect(page).not_to have_content("Recent comments")
        end
      end
    end
  end

  context "when user has an organization membership" do
    before do
      Timecop.freeze
      user.organization_memberships.create(organization: organization, type_of_user: "member")
      visit "/#{user.username}"
    end

    after { Timecop.return }

    it "shows organizations", js: true do
      expect(page).to have_css(".spec-org-titles", text: "Organizations")
    end
  end

  context "when visiting own profile" do
    before do
      Timecop.freeze
      sign_in user
      visit "/#{user.username}"
    end

    after { Timecop.return }

    context "when user is logged in" do
      it "shows_header", :aggregate_failures, js: true do
        within("h1") { expect(page).to have_content(user.name) }
        within(".profile-header__actions") do
          expect(page).to have_button(I18n.t("core.edit_profile"))
        end
      end

      it "shows_articles", :aggregate_failures, js: true do
        within(".crayons-story") do
          expect(page).to have_content(article.title)
          expect(page).not_to have_content(other_article.title)
        end
      end

      it "shows_comments", :aggregate_failures, js: true do
        within("#substories div.profile-comment-card") do
          expect(page).to have_content("Recent comments")
          expect(page).to have_link(nil, href: comment.path)
        end
      end

      it "hides_comments_locked_cta", :aggregate_failures, js: true do
        within("#substories") do
          expect(page).not_to have_content("Want to connect with #{user.name}?")
        end
      end
    end

    it "shows_last_comments", :aggregate_failures, js: true do
      stub_const("CommentsHelper::MAX_COMMENTS_TO_RENDER", 1)
      visit "/#{user.username}"
      within("#substories .profile-comment-card .pt-3 .fs-base") do
        expect(page).to have_content("View last 1 Comment")
      end
    end
  end
end
