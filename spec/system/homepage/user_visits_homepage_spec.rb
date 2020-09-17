require "rails_helper"

RSpec.describe "User visits a homepage", type: :system do
  let!(:ruby_tag) { create(:tag, name: "ruby") }

  before { create(:tag, name: "webdev") }

  context "when user hasn't logged in" do
    it "shows the sign-in block" do
      visit "/"
      within ".signin-cta-widget" do
        expect(page).to have_text("Log in")
        expect(page).to have_text("Create new account")
      end
    end

    it "shows the tags block" do
      visit "/"
      within("#sidebar-nav-default-tags") do
        Tag.where(supported: true).limit(30).each do |tag|
          expect(page).to have_link("##{tag.name}", href: "/t/#{tag.name}")
        end
      end

      expect(page).to have_text("DESIGN YOUR EXPERIENCE")
    end

    describe "link tags" do
      it "contains the qualified community name in the search link" do
        visit "/"
        selector = "link[rel='search'][title='#{community_qualified_name}']"
        expect(page).to have_selector(selector, visible: :hidden)
      end
    end
  end

  context "when logged in user" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it "offers to follow tags", js: true do
      visit "/"

      within("#sidebar-nav-default-tags") do
        expect(page).to have_text("FOLLOW TAGS TO IMPROVE YOUR FEED")
      end
    end

    context "when rendering broadcasts" do
      let!(:broadcast) { create(:announcement_broadcast) }

      it "renders the broadcast if active", js: true do
        get "/async_info/base_data" # Explicitly ensure broadcast data is loaded before doing any checks
        visit "/"
        within ".broadcast-wrapper" do
          expect(page).to have_text("Hello, World!")
        end
      end

      it "does not render a broadcast if inactive", js: true do
        broadcast.update!(active: false)
        get "/async_info/base_data" # Explicitly ensure broadcast data is loaded before doing any checks
        visit "/"
        expect(page).not_to have_css(".broadcast-wrapper")
      end
    end

    context "when user follows tags" do
      before do
        user.follows.create!(followable: ruby_tag)
        user.follows.create!(followable: create(:tag, name: "go", hotness_score: 99))
        user.follows.create!(followable: create(:tag, name: "javascript"), points: 3)

        visit "/"
      end

      it "shows the followed tags", js: true do
        expect(page).to have_text("MY TAGS")

        # Need to ensure the user data is loaded before doing any checks
        find("body")["data-user"]

        within("#sidebar-nav-followed-tags") do
          expect(page).to have_link("#ruby", href: "/t/ruby")
        end
      end

      it "shows followed tags ordered by weight and name", js: true, elasticsearch: "FeedContent" do
        # Need to ensure the user data is loaded before doing any checks
        find("body")["data-user"]

        within("#sidebar-nav-followed-tags") do
          expect(all(".spec__tag-link").map(&:text)).to eq(%w[#javascript #go #ruby])
        end
      end

      it "shows other tags", js: true do
        expect(page).to have_text("OTHER POPULAR TAGS")
        within("#sidebar-nav-default-tags") do
          expect(page).to have_link("#webdev", href: "/t/webdev")
          expect(page).not_to have_link("#ruby", href: "/t/ruby")
        end
      end
    end

    describe "shop url" do
      it "shows the link to the shop if present" do
        SiteConfig.shop_url = "https://example.com"

        visit "/"

        within("#main-nav-more") do
          expect(page).to have_link(href: SiteConfig.shop_url)
        end
      end

      it "does not show the shop if not present" do
        SiteConfig.shop_url = ""

        visit "/"

        within("#main-nav-more") do
          expect(page).not_to have_text("Shop")
        end
      end
    end
  end
end
