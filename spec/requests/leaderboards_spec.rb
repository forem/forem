require "rails_helper"

RSpec.describe "Leaderboards" do
  describe "GET /leaderboard" do
    let!(:user_high) { create(:user, name: "Alice", username: "alice", badge_achievements_count: 5) }
    let!(:user_low) { create(:user, name: "Bob", username: "bob", badge_achievements_count: 2) }
    let!(:user_suspended) { create(:user, :suspended, name: "Charlie", username: "charlie", badge_achievements_count: 10) }
    let!(:user_spam) { create(:user, :spam, name: "David", username: "david", badge_achievements_count: 12) }

    it "renders the leaderboard page successfully" do
      get "/leaderboard"
      expect(response).to have_http_status(:ok)
    end

    it "displays the user's recent badges" do
      badge = create(:badge, title: "Super Author", slug: "super-author")
      create(:badge_achievement, user: user_high, badge: badge)

      get "/leaderboard"
      expect(response.body).to include("Super Author")
      expect(response.body).to include(CGI.escapeHTML(badge.badge_image_url))
    end

    it "displays only registered, non-suspended, non-spam users ordered by badge achievements count" do
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

    it "excludes users with 0 badge achievements" do
      create(:user, name: "ZeroBadgeUser", username: "zerobadge", badge_achievements_count: 0)

      get "/leaderboard"
      expect(response.body).not_to include("ZeroBadgeUser")
      expect(response.body).not_to include("@zerobadge")
    end

    it "excludes mascot and staff accounts" do
      mascot = create(:user, name: "MascotUser", username: "mascot_user", badge_achievements_count: 8)
      staff = create(:user, name: "StaffUser", username: "staff_user", badge_achievements_count: 7)

      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot.id)
      allow(Settings::Community).to receive(:staff_user_id).and_return(staff.id)

      get "/leaderboard"

      expect(response.body).not_to include("MascotUser")
      expect(response.body).not_to include("@mascot_user")
      expect(response.body).not_to include("StaffUser")
      expect(response.body).not_to include("@staff_user")
    end

    it "lists users in descending order of badge achievements count" do
      get "/leaderboard"

      # Since Alice has 5 badges and Bob has 2, Alice should appear before Bob
      alice_position = response.body.index("Alice")
      bob_position = response.body.index("Bob")

      expect(alice_position).to be < bob_position
    end

    it "limits the results to 100 users" do
      # Create 105 more users
      create_list(:user, 105, badge_achievements_count: 1)

      get "/leaderboard"
      # There should be exactly 100 rows rendered
      row_count = response.body.scan(/leaderboard-row/).length
      expect(row_count).to eq(100)
    end
  end
end
