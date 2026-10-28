require "rails_helper"

RSpec.describe "Leaderboards" do
  describe "GET /leaderboard" do
    let!(:user_high) { create_leaderboard_user(name: "Alice", username: "alice", badge_achievements_count: 5) }
    let!(:user_low) { create_leaderboard_user(name: "Bob", username: "bob", badge_achievements_count: 2) }

    def create_leaderboard_user(*traits, **attrs)
      create(:user, :without_profile, *traits, profile_image: nil, **attrs)
    end

    it "renders the leaderboard with 1-minute edge cache headers and descending badge order", :aggregate_failures do
      get "/leaderboard"

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to eq("public, no-cache")
      expect(response.headers["Surrogate-Control"]).to include("max-age=60")
      expect(response.body.index(user_high.name)).to be < response.body.index(user_low.name)
    end

    it "displays the user's recent badges", :aggregate_failures do
      badge = create(:badge, title: "Super Author", slug: "super-author")
      create(:badge_achievement, user: user_high, badge: badge)

      get "/leaderboard"
      expect(response.body).to include("Super Author")
      expect(response.body).to include(CGI.escapeHTML(badge.badge_image_url))
    end

    it "displays only registered, non-suspended, non-spam users", :aggregate_failures do
      create_leaderboard_user(:suspended, name: "Charlie", username: "charlie", badge_achievements_count: 10)
      create_leaderboard_user(:spam, name: "David", username: "david", badge_achievements_count: 12)

      get "/leaderboard"

      # Alice and Bob should be displayed
      expect(response.body).to include("Alice")
      expect(response.body).to include("@alice")
      expect(response.body).to include("5")

      expect(response.body).to include("Bob")
      expect(response.body).to include("@bob")
      expect(response.body).to include("2")

      # Charlie and David should NOT be displayed as they are suspended/spam
      expect(response.body).not_to include("Charlie")
      expect(response.body).not_to include("@charlie")

      expect(response.body).not_to include("David")
      expect(response.body).not_to include("@david")
    end

    it "excludes users with 0 badge achievements", :aggregate_failures do
      create_leaderboard_user(name: "ZeroBadgeUser", username: "zerobadge", badge_achievements_count: 0)

      get "/leaderboard"
      expect(response.body).not_to include("ZeroBadgeUser")
      expect(response.body).not_to include("@zerobadge")
    end

    it "excludes mascot and staff accounts", :aggregate_failures do
      mascot = create_leaderboard_user(name: "MascotUser", username: "mascot_user", badge_achievements_count: 8)
      staff = create_leaderboard_user(name: "StaffUser", username: "staff_user", badge_achievements_count: 7)

      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot.id)
      allow(Settings::Community).to receive(:staff_user_id).and_return(staff.id)

      get "/leaderboard"

      expect(response.body).not_to include("MascotUser")
      expect(response.body).not_to include("@mascot_user")
      expect(response.body).not_to include("StaffUser")
      expect(response.body).not_to include("@staff_user")
    end

    it "limits the results to 100 users" do
      now = Time.current
      User.insert_all(
        Array.new(105) do |i|
          {
            name: "Leaderboard User #{i}",
            username: "leaderboard_user_#{i}",
            email: "leaderboard_#{i}@example.com",
            registered: true,
            badge_achievements_count: 1,
            created_at: now,
            updated_at: now
          }
        end,
      )

      get "/leaderboard"
      # There should be exactly 100 rows rendered
      row_count = response.body.scan("leaderboard-row").length
      expect(row_count).to eq(100)
    end

    context "with fragment caching enabled" do
      around do |example|
        original_cache_store = ActionController::Base.cache_store
        original_perform_caching = ActionController::Base.perform_caching

        ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
        ActionController::Base.perform_caching = true

        example.run
      ensure
        ActionController::Base.perform_caching = original_perform_caching
        ActionController::Base.cache_store = original_cache_store
      end

      it "busts the cache and displays updated user name" do
        get "/leaderboard"
        expect(response.body).to include("Alice")

        user_high.update!(name: "Alice Modified", profile_updated_at: Time.current)

        get "/leaderboard"
        expect(response.body).to include("Alice Modified")
        expect(response.body).not_to include(">Alice</a>")
      end

      it "busts the cache and displays updated badge counts when a new badge is achieved" do
        get "/leaderboard"
        expect(response.body).to include("Alice")
        expect(response.body).to include("5")

        badge = create(:badge, title: "Super Author", slug: "super-author")
        create(:badge_achievement, user: user_high, badge: badge)
        user_high.reload

        get "/leaderboard"
        expect(response.body).to include("Super Author")
        expect(response.body).to include("6")
      end
    end
  end
end
