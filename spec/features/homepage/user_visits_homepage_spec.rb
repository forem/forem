require "rails_helper"

describe "User visits a homepage", type: :feature do
  let!(:ruby_tag) { create(:tag, name: "ruby") }

  before { create(:tag, name: "webdev") }

  context "when user hasn't logged in" do
    before { visit "/" }

    it "shows the sign-in block" do
      within ".signin-cta-widget" do
        expect(page).to have_text("SIGN IN VIA TWITTER")
        expect(page).to have_text("SIGN IN VIA GITHUB")
      end
    end

    it "shows the tags block" do
      within("#sidebar-nav-default-tags") do
        expect(page).to have_link("#ruby", href: "/t/ruby")
        expect(page).to have_link("#webdev", href: "/t/webdev")
      end
      expect(page).to have_text("design your experience")
    end
  end

  context "when logged in user" do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    it "shows profile content", js: true do
      visit "/"
      within("div#sidebar-profile-username") do
        expect(page).to have_text(user.username)
      end
      expect(page).not_to have_text("SIGN IN VIA")
    end

    it "offers to follow tags", js: true do
      visit "/"
      within("#sidebar-nav-default-tags") do
        expect(page).to have_text("Follow tags to improve your feed")
      end
    end

    context "when user follows tags" do
      before do
        user.follows.create!(followable: ruby_tag)
        user.follows.create!(followable: create(:tag, name: "go"), points: 3)
        user.follows.create!(followable: create(:tag, name: "javascript"))

        visit "/"
      end

      it "shows the followed tags", js: true do
        expect(page).to have_text("my tags")
        within("#sidebar-nav-followed-tags") do
          expect(page).to have_link("#ruby", href: "/t/ruby")
        end
      end

      it "shows followed tags ordered by weight and name", js: true do
        within("#sidebar-nav-followed-tags") do
          expect(all(".sidebar-nav-tag-text").map(&:text)).to eq(%w[#go #javascript #ruby])
        end
      end

      it "shows other tags", js: true do
        expect(page).to have_text("Other Popular Tags")
        within("#sidebar-nav-default-tags") do
          expect(page).to have_link("#webdev", href: "/t/webdev")
          expect(page).not_to have_link("#ruby", href: "/t/ruby")
        end
      end
    end
  end
end
