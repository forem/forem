require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/badge_achievements", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Badge do
    let(:request) { get "/admin/badge_achievements" }
  end

  describe "POST /admin/badges/award_badges" do
    let(:admin) { create(:user, :super_admin) }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:badge) { create(:badge) }
    let(:usernames_string) { "#{user.username}, #{user2.username}" }
    let(:usernames_array) { [user.username, user2.username] }

    before do
      sign_in admin
      allow(BadgeAchievements::BadgeAwardWorker).to receive(:perform_async)
    end

    it "awards badges" do
      allow(BadgeAchievements::BadgeAwardWorker).to receive(:perform_async)
      post admin_badges_award_badges_path, params: {
        badge: badge.slug,
        usernames: usernames_string,
        message_markdown: "Hinder me? Thou fool. No living man may hinder me!"
      }
      expect(BadgeAchievements::BadgeAwardWorker).to have_received(:perform_async).with(
        usernames_array, badge.slug, "Hinder me? Thou fool. No living man may hinder me!"
      )
      expect(request.flash[:success]).to include("Badges are being rewarded. The task will finish shortly.")
    end

    it "awards badges with default a message" do
      allow(BadgeAchievements::BadgeAwardWorker).to receive(:perform_async)
      post admin_badges_award_badges_path, params: {
        badge: badge.slug,
        usernames: usernames_string,
        message_markdown: ""
      }
      expect(BadgeAchievements::BadgeAwardWorker).to have_received(:perform_async).with(usernames_array, badge.slug,
                                                                                        "Congrats!")
      expect(request.flash[:success]).to include("Badges are being rewarded. The task will finish shortly.")
    end

    it "does not award a badge and raises an error if a badge is not specified" do
      post admin_badges_award_badges_path, params: {
        usernames: usernames_string,
        message_markdown: ""
      }
      expect(BadgeAchievements::BadgeAwardWorker).not_to have_received(:perform_async).with(usernames_array,
                                                                                            badge.slug, "")
    end
  end
end
