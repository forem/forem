require "rails_helper"

RSpec.describe Moderator::MergeUser, type: :service do
  let!(:keep_user) { create(:user) }
  let!(:delete_user) { create(:user) }
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

    it "updates badge_achievements_count" do
      create_list(:badge_achievement, 2, user: delete_user)

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end

      expect(keep_user.reload.badge_achievements_count).to eq(2)
    end
  end
end
