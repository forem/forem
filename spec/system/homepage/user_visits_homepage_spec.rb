require "rails_helper"

RSpec.describe "User visits a homepage", type: :system do
  let!(:ruby_tag) { create(:tag, name: "ruby") }

  before { create(:tag, name: "webdev") }

  context "when user hasn't logged in" do
    before { visxit "/" }

    xit "renders the page", js: true, percy: true do
      Percy.snapshot(page, name: "Visits homepage: logged out user")
    end

    xit "shows the sign-in block" do
      within ".signin-cta-widget" do
        expect(page).to have_text("Sign In With Twitter")
        expect(page).to have_text("Sign In With GitHub")
      end
    end

    xit "shows the tags block" do
      within("#sidebar-nav-default-tags") do
        Tag.where(supported: true).limit(30).each do |tag|
          expect(page).to have_link("##{tag.name}", href: "/t/#{tag.name}")
        end
      end

      expect(page).to have_text("Design Your Experience")
    end

    describe "link tags" do
      xit "contains the qualified community name in the search link" do
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

    xit "renders the page", js: true, percy: true do
      Percy.snapshot(page, name: "Visits homepage: logged in user")
    end

    xit "offers to follow tags", js: true do
      visxit "/"

      within("#sidebar-nav-default-tags") do
        expect(page).to have_text("Follow tags to improve your feed")
      end
    end

    context "when user follows tags" do
      before do
        user.follows.create!(followable: ruby_tag)
        user.follows.create!(followable: create(:tag, name: "go", hotness_score: 99))
        user.follows.create!(followable: create(:tag, name: "javascript"), points: 3)

        visxit "/"
      end

      xit "shows the followed tags", js: true do
        expect(page).to have_text("My Tags")

        # Need to ensure the user data is loaded before doing any checks
        find("body")["data-user"]

        within("#sidebar-nav-followed-tags") do
          expect(page).to have_link("#ruby", href: "/t/ruby")
        end
      end

      xit "shows followed tags ordered by weight and name", js: true do
        # Need to ensure the user data is loaded before doing any checks
        find("body")["data-user"]

        within("#sidebar-nav-followed-tags") do
          expect(all(".sidebar-nav-tag-text").map(&:text)).to eq(%w[#javascript #go #ruby])
        end
      end

      xit "shows other tags", js: true do
        expect(page).to have_text("Other Popular Tags")
        within("#sidebar-nav-default-tags") do
          expect(page).to have_link("#webdev", href: "/t/webdev")
          expect(page).not_to have_link("#ruby", href: "/t/ruby")
        end
      end
    end

    describe "shop url" do
      xit "shows the link to the shop if present" do
        SiteConfig.shop_url = "https://example.com"

        visxit "/"

        within("#main-nav-more") do
          expect(page).to have_link(href: SiteConfig.shop_url)
        end
      end

      xit "does not show the shop if not present" do
        SiteConfig.shop_url = ""

        visxit "/"

        within("#main-nav-more") do
          expect(page).not_to have_text("Shop")
        end
      end
    end
  end
end
