require "rails_helper"

RSpec.describe "User visits articles by tag", type: :system do
  let(:js_tag) { create(:tag, name: "javascript") }
  let(:iot_tag) { create(:tag, name: "IoT") }
  let!(:func_tag) { create(:tag, name: "functional") }

  let(:author) { create(:user) }
  let!(:article) { create(:article, tags: "javascript, IoT", user: author, published_at: 2.days.ago) }
  let!(:article2) { create(:article, tags: "functional", user: author, published_at: Time.current) }
  let!(:article3) { create(:article, tags: "functional, javascript", user: author, published_at: 2.weeks.ago) }

  context "when user hasn't logged in" do
    context "when 2 articles" do
      before { visit "/t/javascript" }

      it "shows the header", js: true do
        within("h1") { expect(page).to have_text("javascript") }
      end

      it "shows the follow button", js: true do
        within("h1") { expect(page).to have_button("+ FOLLOW") }
      end

      it "shows time buttons" do
        within("#on-page-nav-controls") do
          expect(page).to have_link("WEEK", href: "/t/javascript/top/week")
          expect(page).to have_link("INFINITY", href: "/t/javascript/top/infinity")
          expect(page).to have_link("LATEST", href: "/t/javascript/latest")
        end
      end

      it "shows correct articles count" do
        expect(page).to have_selector(".single-article", count: 2)
      end

      it "shows the correct articles" do
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).to have_text(article3.title)
          expect(page).not_to have_text(article2.title)
        end
      end

      it "when user clicks 'week'" do
        click_on "WEEK"
        within("#articles-list") do
          expect(page).to have_text(article.title)
          expect(page).not_to have_text(article3.title)
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

      within("h1") { expect(page).to have_button("✓ FOLLOWING") }
    end
  end
end
