require "rails_helper"

RSpec.describe "User visits a homepage" do
  context "when user hasn't logged in" do
    it "shows the sign-in block, popular tags block, and search link tag", :aggregate_failures do
      create(:tag, name: "ruby")
      create(:tag, name: "webdev")

      visit "/"

      within "#sidebar-wrapper-left" do
        expect(page).to have_text(I18n.t("views.main.header.login"))
        expect(page).to have_text(I18n.t("views.main.header.create_account"))
      end

      within("#sidebar-nav-default-tags") do
        Tag.supported.limit(30).each do |tag|
          expect(page).to have_link("##{tag.name}", href: "/t/#{tag.name}")
        end
      end

      expect(page).to have_text("Popular Tags")
      expect(page).to have_css("link[rel='search'][title='#{community_name}']", visible: :hidden)
    end

    describe "navigation_links" do
      before do
        create(:navigation_link,
               name: "Listings",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/> </svg>",
               display_to: :logged_in,
               position: 1)
        create(:navigation_link,
               name: "Shop",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/> </svg>",
               display_to: :all,
               position: 2)
        create(:navigation_link,
               :other_section_link,
               name: "Podcasts",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/> </svg>",
               display_to: :all,
               position: nil)
        create(:navigation_link,
               :other_section_link,
               name: "Privacy Policy",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/> </svg>",
               display_to: :all,
               position: 1)
        visit "/"
      end

      it "shows expected links when signed out and hides the Other section when empty", :aggregate_failures do
        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_css(".sidebar-navigation-link", count: 2)
          expect(page).to have_css(".default-navigation-links .sidebar-navigation-link", count: 2)
        end

        within("nav[data-testid='other-nav']", match: :first) do
          expect(page).to have_css(".other-navigation-links")
          expect(page).to have_css(".sidebar-navigation-link", count: 2)
        end

        NavigationLink.other_section.destroy_all
        visit "/"

        expect(page).to have_no_css("nav[data-testid='other-nav']")
      end

      it "shows links in their correct section and order", :aggregate_failures do
        create(:navigation_link,
               name: "Mock",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/> </svg>",
               display_to: :all,
               position: 3)
        visit "/"

        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_css(".default-navigation-links li:nth-child(1)", text: "Shop")
          expect(page).to have_css(".default-navigation-links li:nth-child(2)", text: "Mock")
        end
      end
    end
  end

  context "when logged in user" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    context "when user follows tags" do
      before do
        user.follows.create!(followable: create(:tag, name: "ruby"))
        user.follows.create!(followable: create(:tag, name: "go", hotness_score: 99))
        user.follows.create!(followable: create(:tag, name: "javascript"), points: 3)
        user.update!(following_tags_count: 3)

        visit "/"
      end

      it "shows the followed tags ordered by weight and name", :aggregate_failures, :js do
        expect(page).to have_css("body[data-loaded='true']")
        expect(page).to have_text("My Tags")
        expect(page).to have_css("#sidebar-nav-followed-tags a", text: "#ruby")
        expect(page).to have_css("#sidebar-nav-followed-tags .c-link--block", count: 3)
        expect(all("#sidebar-nav-followed-tags .c-link--block").map(&:text).sort).to eq(%w[#javascript #go #ruby].sort)
      end
    end

    describe "navigation_links" do
      let!(:navigation_link_1) do
        create(:navigation_link,
               name: "Reading List",
               url: app_url("readinglist").to_s,
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/> </svg>",
               display_to: :all,
               position: 1)
      end
      let!(:navigation_link_2) do
        create(:navigation_link,
               :other_section_link,
               name: "Podcasts",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/> </svg>",
               display_to: :all,
               position: nil)
      end
      let!(:navigation_link_3) do
        create(:navigation_link,
               name: "Beauty",
               icon: "<svg xmlns='http://www.w3.org/2000/svg'/> </svg>",
               display_to: :logged_in,
               position: nil)
      end

      before do
        visit "/"
      end

      it "shows the expected navigation links, urls, and order when signed in", :aggregate_failures do
        within("nav[data-testid='main-nav']", match: :first) do
          expect(page).to have_text(navigation_link_1.name)
          expect(page).to have_text(navigation_link_3.name)
          expect(page).to have_link(href: navigation_link_1.url)
          expect(page).to have_link(href: navigation_link_3.url)
          expect(page).to have_css(".sidebar-navigation-link", count: 3)
          expect(page).to have_css(".default-navigation-links li:nth-child(2)", text: "Beauty")
        end

        within("nav[data-testid='other-nav']", match: :first) do
          expect(page).to have_text(navigation_link_2.name)
          expect(page).to have_link(href: navigation_link_2.url)
        end
      end
    end
  end
end
