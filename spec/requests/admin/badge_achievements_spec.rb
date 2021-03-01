require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/badges", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let!(:badge) { create(:badge, title: "Not 'Hello, world!'") }
  let(:params) do
    {
      badge: {
        title: "Hello, world!",
        slug: "greeting-badge",
        description: "Awarded to welcoming users",
        badge_image: Rack::Test::UploadedFile.new("spec/support/fixtures/images/image1.jpeg", "image/jpeg")
      }
    }
  end

  it_behaves_like "an InternalPolicy dependant request", Badge do
    let(:request) { get "/admin/badges" }
  end

  describe "POST /admin/badge_achievements/award_badges" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:usernames_string) { "#{user.username}, #{user2.username}" }
    let(:usernames_array) { [user.username, user2.username] }

    before do
      sign_in admin
      allow(BadgeAchievements::BadgeAwardWorker).to receive(:perform_async)
    end

    context "when the user is a single resource admin" do
      it "awards the badge" do
        user.add_role(:single_resource_admin, BadgeAchievement)
        sign_in user
        allow(BadgeAchievements::BadgeAwardWorker).to receive(:perform_async)

        post admin_badge_achievements_award_badges_path, params: {
          badge: badge.slug,
          usernames: usernames_string,
          message_markdown: "you got a badge nice one"
        }
        expect(BadgeAchievements::BadgeAwardWorker).to have_received(:perform_async).with(
          usernames_array, badge.slug, "you got a badge nice one"
        )
        expect(request.flash[:success]).to include("Badges are being rewarded. The task will finish shortly.")
      end
    end

    it "awards badges" do
      allow(BadgeAchievements::BadgeAwardWorker).to receive(:perform_async)
      post admin_badge_achievements_award_badges_path, params: {
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
      post admin_badge_achievements_award_badges_path, params: {
        badge: badge.slug,
        usernames: usernames_string,
        message_markdown: ""
      }
      expect(BadgeAchievements::BadgeAwardWorker).to have_received(:perform_async).with(usernames_array, badge.slug,
                                                                                        "Congrats!")
      expect(request.flash[:success]).to include("Badges are being rewarded. The task will finish shortly.")
    end

    it "does not award a badge and raises an error if a badge is not specified" do
      post admin_badge_achievements_award_badges_path, params: {
        usernames: usernames_string,
        message_markdown: ""
      }
      expect(BadgeAchievements::BadgeAwardWorker).not_to have_received(:perform_async).with(usernames_array,
                                                                                            badge.slug, "")
    end

    it "does not award a badge if the username provided is not lowercase" do
      post admin_badge_achievements_award_badges_path, params: {
        badge: badge.slug,
        usernames: user.username.upcase,
        message_markdown: ""
      }
      expect(BadgeAchievements::BadgeAwardWorker).not_to have_received(:perform_async).with(user.username.upcase,
                                                                                            badge.slug, "")
    end
  end

  describe "DELETE /admin/badge_achievements/:id" do
    let!(:badge_achievement) { create(:badge_achievement) }

    before do
      sign_in admin
    end

    it "deletes the badge_achievement" do
      expect do
        delete "/admin/badge_achievements/#{badge_achievement.id}"
      end.to change { BadgeAchievement.all.count }.by(-1)
      expect(response.body).to redirect_to "/admin/badge_achievements"
    end
  end
end
