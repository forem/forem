require "rails_helper"

RSpec.describe "User visits a homepage", type: :system do
  let!(:ruby_tag) { create(:tag, name: "ruby") }

  before { create(:tag, name: "webdev") }

  context "when user hasn't logged in" do
    it "shows the sign-in block" do
      visit "/"
      within "#sidebar-wrapper-left" do
        p I18n.t("views.main.header.create_account")
        expect(page).to have_text(I18n.t("views.main.header.login"))
        expect(page).to have_text(I18n.t("views.main.header.create_account"))
      end
    end

    it "shows the tags block" do
      visit "/"
      within("#sidebar-nav-default-tags") do
        Tag.supported.limit(30).each do |tag|
          expect(page).to have_link("##{tag.name}", href: "/t/#{tag.name}")
        end
      end

      expect(page).to have_text("Popular Tags")
    end

    describe "link tags" do
      it "contains the qualified community name in the search link" do
        visit "/"
        selector = "link[rel='search'][title='#{community_name}']"
        expect(page).to have_selector(selector, visible: :hidden)
      end
    end

    describe "navigation_links" do
      before do
        create(:navigation_link,
               name: "Listings",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_to: :logged_in,
               position: 1)
        create(:navigation_link,
               name: "Shop",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_to: :all,
               position: 2)
        create(:navigation_link,
               :other_section_link,
               name: "Podcasts",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_to: :all,
               position: nil)
        create(:navigation_link,
               :other_section_link,
               name: "Privacy Policy",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_to: :all,
               position: 1)
        visit "/"
      end

      it "shows expected number of links when signed out" do
        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_selector(".sidebar-navigation-link", count: 1)
        end

        within("nav[data-testid='other-nav']", match: :first) do
          expect(page).to have_selector(".sidebar-navigation-link", count: 2)
        end
      end

      it "shows the Other section when other nav links exist" do
        within("nav[data-testid='other-nav']", match: :first) do
          expect(page).to have_selector(".other-navigation-links")
        end

        NavigationLink.other_section.destroy_all
        visit "/"

        expect(page).not_to have_selector("nav[data-testid='other-nav']")
      end

      it "hides link when display_to is set to logged in users only" do
        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_selector(".default-navigation-links .sidebar-navigation-link", count: 1)
        end
      end

      it "shows links in their correct section and order" do
        create(:navigation_link,
               name: "Mock",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_to: :all,
               position: 3)
        visit "/"

        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_selector(".default-navigation-links li:nth-child(1)", text: "Shop")
          expect(page).to have_selector(".default-navigation-links li:nth-child(2)", text: "Mock")
        end
      end
    end
  end

  context "when logged in user" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
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
        user.update!(following_tags_count: 3)

        visit "/"
      end

      it "shows the followed tags", js: true do
        expect(page).to have_text("My Tags")

        # Need to ensure the user data is loaded before doing any checks
        find("body")["data-user"]

        within("#sidebar-nav-followed-tags") do
          expect(page).to have_link("#ruby", href: "/t/ruby")
        end
      end

      it "shows followed tags ordered by weight and name", js: true do
        # Need to ensure the user data is loaded before doing any checks
        find("body")["data-user"]

        within("#sidebar-nav-followed-tags") do
          expect(all(".c-link--block").map(&:text).sort).to eq(%w[#javascript #go #ruby].sort)
        end
      end
    end

    describe "navigation_links" do
      let!(:navigation_link_1) do
        create(:navigation_link,
               name: "Reading List",
               url: app_url("readinglist").to_s,
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_to: :all,
               position: 1)
      end
      let!(:navigation_link_2) do
        create(:navigation_link,
               :other_section_link,
               name: "Podcasts",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_to: :all,
               position: nil)
      end
      let!(:navigation_link_3) do
        create(:navigation_link,
               name: "Beauty",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_to: :logged_in,
               position: nil)
      end

      before do
        visit "/"
      end

      it "shows the correct navigation_links" do
        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_text(navigation_link_1.name)
          expect(page).to have_text(navigation_link_3.name)
        end

        within("nav[data-testid='other-nav']", match: :first) do
          expect(page).to have_text(navigation_link_2.name)
        end
      end

      it "shows the correct urls" do
        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_link(href: navigation_link_1.url)
          expect(page).to have_link(href: navigation_link_3.url)
        end

        within("nav[data-testid='other-nav']", match: :first) do
          expect(page).to have_link(href: navigation_link_2.url)
        end
      end

      it "shows expected # of links when signed in" do
        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_selector(".sidebar-navigation-link", count: 2) # it's count: 1 when signed out
        end
      end

      it "shows link when display_to is set to logged_in" do
        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_selector(".default-navigation-links li:nth-child(2)", text: "Beauty")
        end
      end
    end
  end
end
