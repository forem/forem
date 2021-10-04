require "rails_helper"

RSpec.describe "User visits articles by tag", type: :system do
  let(:js_tag) { create(:tag, name: "javascript") }
  let(:iot_tag) { create(:tag, name: "IoT") }
  let!(:func_tag) { create(:tag, name: "functional") }

  let(:author) { create(:user, profile_image: nil) }
  let!(:article) { create(:article, tags: "javascript, IoT", user: author, published_at: 2.days.ago, score: 5) }
  let!(:article2) { create(:article, tags: "functional", user: author, published_at: Time.current, score: 5) }
  let!(:article3) do
    create(:article, tags: "functional, javascript", user: author, published_at: 2.weeks.ago, score: 5)
  end

  context "when user hasn't logged in" do
    context "when 2 articles" do
      before do
        visit "/t/javascript"
      end

      it "shows the header", js: true do
        within("h1") { expect(page).to have_text("javascript") }
      end

      it "shows the follow button", js: true do
        within("header.tag-header") { expect(page).to have_button(I18n.t("core.follow")) }
      end

      # Regression test for https://github.com/forem/forem/pull/12724
      it "does not display a comment count of 0", js: true do
        expect(page).to have_text("Add Comment")
        expect(page).not_to have_text("0 #{I18n.t('core.comment').downcase}s")
      end

      it "shows correct articles count" do
        expect(page).to have_selector(".crayons-story", count: 2)
      end

      it "shows the correct articles" do
        within("#main-content") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(article3.title)
          expect(page).not_to have_text(article2.title)
        end
      end
    end

    context "when more articles" do
      it "visits ok" do
        create_list(:article, 3, tags: "javascript", user: author, published_at: Time.current)
        visit "/t/javascript"
      end
    end
  end

  context "when user has logged in" do
    let(:user) { create(:user) }

    before do
      user.follows.create(followable: func_tag)
      sign_in user
      visit "/t/functional"
    end

    it "shows the following button", js: true do
      wait_for_javascript

      within("header.tag-header") { expect(page).to have_button(I18n.t("core.following")) }
    end

    it "shows time buttons" do
      within("#on-page-nav-controls") do
        expect(page).to have_link("Week", href: "/t/functional/top/week")
        expect(page).to have_link("Infinity", href: "/t/functional/top/infinity")
        expect(page).to have_link("Latest", href: "/t/functional/latest")
      end
    end
  end
end
