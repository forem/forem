require "rails_helper"

RSpec.describe "/internal/badges", type: :request do
  describe "POST /internal/badges/award_badges" do
    let(:admin) { create(:user, :super_admin) }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:badge) { create(:badge) }

    before do
      sign_in admin
    end

    it "awards badges" do
      expect do
        post internal_badges_award_badges_path, params: {
          badge: badge.slug,
          usernames: "#{user.username}, #{user2.username}",
          message_markdown: "Hinder me? Thou fool. No living man may hinder me!"
        }
      end.to change { user.badges.count }.by(1).and change { user2.badges.count }.by(1)
    end

    it "awards badges without a message" do
      expect do
        post internal_badges_award_badges_path, params: {
          badge: badge.slug,
          usernames: "#{user.username}, #{user2.username}",
          message_markdown: ""
        }
      end.to change { user.badges.count }.by(1).and change { user2.badges.count }.by(1)
    end

    it "does not award a badge and raises an error if a badge is not specified" do
      expect do
        post internal_badges_award_badges_path, params: {
          usernames: "#{user.username}, #{user2.username}",
          message_markdown: ""
        }
      end.to change { user.badges.count }.by(0)
    end
  end
end
