require "rails_helper"

RSpec.describe "User visits articles by tag" do
  context "when user hasn't logged in" do
    let(:author) { create(:user, profile_image: nil) }
    let!(:article) do
      create(:article, :past, past_published_at: 2.days.ago, tags: "javascript, IoT", user: author, score: 5)
    end
    let!(:article2) { create(:article, tags: "functional", user: author, published_at: Time.current, score: 5) }
    let!(:article3) do
      create(:article, :past, past_published_at: 2.weeks.ago, tags: "functional, javascript", user: author, score: 5)
    end

    context "when 2 articles" do
      before do
        visit "/t/javascript"
      end

      # Regression test for https://github.com/forem/forem/pull/12724
      it "shows the header, follow button, articles, and hides zero comment count", :aggregate_failures do
        within("h1.crayons-title") { expect(page).to have_text("javascript") }
        within("header.spec__tag-header") { expect(page).to have_button(I18n.t("core.follow")) }
        expect(page).to have_text("Add Comment")
        expect(page).to have_no_text("0 #{I18n.t('core.comment').downcase}s")
        expect(page).to have_css(".crayons-story", count: 2)
        within("#main-content") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(article3.title)
          expect(page).to have_no_text(article2.title)
        end
      end
    end
  end

  context "when user has logged in" do
    let(:func_tag) { create(:tag, name: "functional") }
    let(:user) { create(:user) }

    before do
      user.follows.create(followable: func_tag)
      sign_in user
      visit "/t/functional"
    end

    it "shows the following button and top level sort options", :aggregate_failures, :js do
      wait_for_javascript

      within("header.spec__tag-header") { expect(page).to have_button(I18n.t("core.following")) }

      within("#on-page-nav-controls") do
        expect(page).to have_link("Relevant", href: "/t/functional")
        expect(page).to have_link("Top", href: "/t/functional/top/week")
        expect(page).to have_link("Latest", href: "/t/functional/latest")
      end
    end
  end
end
