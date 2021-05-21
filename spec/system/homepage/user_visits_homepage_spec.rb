require "rails_helper"

RSpec.describe "User visits a homepage", type: :system do
  let!(:ruby_tag) { create(:tag, name: "ruby") }

  before { create(:tag, name: "webdev") }

  context "when user hasn't logged in" do
    it "shows the sign-in block" do
      visit "/"
      within "#sidebar-wrapper-left" do
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
               display_only_when_signed_in: true,
               position: 1)
        create(:navigation_link,
               name: "Podcasts",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_only_when_signed_in: false,
               position: nil)
      end

      it "shows the correct count of links" do
        visit "/"
        expect(page).to have_selector(".spec-sidebar-navigation-links", count: 2)

        within(".spec-sidebar-navigation-links", match: :first) do
          expect(page).to have_selector(".sidebar-navigation-link", count: 1)
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
          expect(all(".crayons-link--block").map(&:text).sort).to eq(%w[#javascript #go #ruby].sort)
        end
      end
    end

    context "when rendering < 5 navigation links" do
      let!(:navigation_link_1) do
        create(:navigation_link,
               name: "Reading List",
               url: app_url("readinglist").to_s,
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_only_when_signed_in: false,
               position: 1)
      end
      let!(:navigation_link_2) do
        create(:navigation_link,
               name: "Podcasts",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_only_when_signed_in: false,
               position: nil)
      end
      let!(:navigation_link_3) do
        create(:navigation_link,
               name: "Beauty",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/></svg>",
               display_only_when_signed_in: true,
               position: nil)
      end

      before do
        visit "/"
      end

      it "shows the correct count of links" do
        within(".spec-sidebar-navigation-links", match: :first) do
          expect(page).to have_selector(".sidebar-navigation-link", count: 3)
        end
      end

      it "shows the correct navigation_links" do
        within(".spec-sidebar-navigation-links", match: :first) do
          expect(page).to have_text(navigation_link_1.name)
          expect(page).to have_text(navigation_link_2.name)
          expect(page).to have_text(navigation_link_3.name)
        end
      end

      it "shows the correct urls" do
        within(".spec-sidebar-navigation-links", match: :first) do
          expect(page).to have_link(href: navigation_link_1.url)
          expect(page).to have_link(href: navigation_link_2.url)
          expect(page).to have_link(href: navigation_link_3.url)
        end
      end

      it "shows the correct order of the links" do
        within(".spec-sidebar-navigation-links", match: :first) do
          sidebar_navigation_link1 = page.find(".sidebar-navigation-link:nth-child(1)")
          expect(sidebar_navigation_link1).to have_text(navigation_link_1.name)

          sidebar_navigation_link2 = page.find(".sidebar-navigation-link:nth-child(2)")
          expect(sidebar_navigation_link2).to have_text(navigation_link_3.name)

          sidebar_navigation_link3 = page.find(".sidebar-navigation-link:nth-child(3)")
          expect(sidebar_navigation_link3).to have_text(navigation_link_2.name)
        end
      end

      it "shows the count when the url /readinglist is added" do
        within(".spec-sidebar-navigation-links", match: :first) do
          within(".sidebar-navigation-link:nth-child(1)") do
            expect(page).to have_selector("#reading-list-count")
          end
        end
      end
    end

    context "when rendering > 5 navigation links" do
      before do
        create_list(:navigation_link, 7)
      end

      it "shows some in the 'More' section" do
        visit "/"
        within(".spec-nav-more", match: :first) do
          expect(page).to have_selector(".sidebar-navigation-link", count: 2)
        end
      end
    end
  end
end
