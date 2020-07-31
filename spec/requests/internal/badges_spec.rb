require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/internal/badges", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Badge do
    let(:request) { get "/internal/badges" }
  end

  describe "POST /internal/badges/award_badges" do
    let(:admin) { create(:user, :super_admin) }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:badge) { create(:badge) }

    before do
      sign_in admin
    end

    it "awards badges" do
      allow(BadgeAchievements::BadgeAwardWorker).to receive(:perform_async)
      post internal_badges_award_badges_path, params: {
        badge: badge.slug,
        usernames: "#{user.username}, #{user2.username}",
        message_markdown: "Hinder me? Thou fool. No living man may hinder me!"
      }
      expect(BadgeAchievements::BadgeAwardWorker).to have_received(:perform_async).with(badge.slug, "#{user.username}, #{user2.username}", "Hinder me? Thou fool. No living man may hinder me!")
      expect(request.flash[:success]).to include("Badges are being rewarded. The task will finish shortly.")
    end

    it "awards badges without a message" do
      allow(BadgeAchievements::BadgeAwardWorker).to receive(:perform_async)
      post internal_badges_award_badges_path, params: {
        badge: badge.slug,
        usernames: "#{user.username}, #{user2.username}",
        message_markdown: ""
      }
      expect(BadgeAchievements::BadgeAwardWorker).to have_received(:perform_async).with(badge.slug, "#{user.username}, #{user2.username}", "")
      expect(request.flash[:success]).to include("Badges are being rewarded. The task will finish shortly.")
    end

    it "does not award a badge and raises an error if a badge is not specified" do
      post internal_badges_award_badges_path, params: {
        usernames: "#{user.username}, #{user2.username}",
        message_markdown: ""
      }
      expect(BadgeAchievements::BadgeAwardWorker).not_to have_received(:perform_async).with(badge.slug, "#{user.username}, #{user2.username}", "")
    end
  end
end
