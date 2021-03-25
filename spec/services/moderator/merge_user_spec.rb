require "rails_helper"

RSpec.describe Moderator::MergeUser, type: :service do
  let!(:keep_user) { create(:user) }
  let!(:delete_user) { create(:user) }
  let(:user) { create(:user) }
  let(:delete_user_id) { delete_user.id }
  let(:admin) { create(:user, :super_admin) }

  describe "#merge" do
    let(:article) { create(:article, user: delete_user) }
    let(:comment) { create(:comment, user: delete_user) }
    let(:reaction) { create(:reaction, user: delete_user, category: "readinglist") }
    let(:article_reaction) { create(:reaction, reactable: article, category: "readinglist") }
    let(:related_records) { [article, comment, reaction, article_reaction] }

    before { sidekiq_perform_enqueued_jobs }

    it "deletes delete_user_id and keeps keep_user" do
      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end
      expect(User.find_by(id: delete_user_id)).to be_nil
      expect(User.find_by(id: keep_user.id)).not_to be_nil
    end

    it "updates documents in Elasticsearch" do
      related_records
      drain_all_sidekiq_jobs
      expect(article.elasticsearch_doc.dig("_source", "user", "id")).to eq(delete_user_id)
      expect(comment.elasticsearch_doc.dig("_source", "user", "id")).to eq(delete_user_id)

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end
      drain_all_sidekiq_jobs
      expect(article.reload.elasticsearch_doc.dig("_source", "user", "id")).to eq(keep_user.id)
      expect(comment.reload.elasticsearch_doc.dig("_source", "user", "id")).to eq(keep_user.id)
    end

    it "merges duplicate badge achievements" do
      badge = create(:badge)
      delete_user_badge = create(:badge_achievement, badge: badge, user: delete_user)
      create(:badge_achievement, badge: badge, user: keep_user)

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end

      expect(Badge.find_by(id: delete_user_badge.id)).to be_nil
    end

    it "merges duplicate reactions without errors" do
      delete_user_rxn = create(:reaction, reactable: article, user: delete_user)
      create(:reaction, reactable: article, user: keep_user)

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end

      expect(Reaction.find_by(id: delete_user_rxn.id)).to be_nil
    end

    it "properly handles updating the role of the chat channel memberships" do
      channel = create(:chat_channel)
      create(:chat_channel_membership, user: delete_user, status: "active", chat_channel: channel, role: "mod")
      create(:chat_channel_membership, user: keep_user, status: "active", chat_channel: channel, role: "member")

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end

      expect(ChatChannelMembership.where(user_id: keep_user.id, role: "mod").count).to eq 1
    end

    it "merges two duplicate chat channel memberships" do
      channel = create(:chat_channel)
      deleted_membership = create(:chat_channel_membership, user: delete_user, status: "active",
                                                            chat_channel: channel, role: "member")
      create(:chat_channel_membership, user: keep_user, status: "active", chat_channel: channel, role: "member")

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end

      expect(ChatChannelMembership.find_by(id: deleted_membership.id)).to be_nil
    end

    it "merges duplicate followers without errors" do
      delete_user_follower = create(:follow, follower: user, followable: delete_user)
      create(:follow, follower: user, followable: keep_user)

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end

      expect(Follow.find_by(id: delete_user_follower.id)).to be_nil
    end

    it "merges duplicate followables without errors" do
      delete_followable_user = create(:follow, follower: delete_user, followable: user)
      create(:follow, follower: keep_user, followable: user)
      tag = create(:tag)
      delete_followable_tag = create(:follow, follower: delete_user, followable: tag)

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end

      expect(Follow.find_by(id: delete_followable_user.id)).to be_nil
      expect(delete_followable_tag.reload.follower_id).to eq keep_user.id
    end
  end
end
