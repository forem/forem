require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:user) { create(:user) }

  context "when creating and enqueueing" do
    it "enqueues the Users::TouchJob" do
      expect do
        create(:reaction, reactable: article, user: user)
      end.to have_enqueued_job(Users::TouchJob).exactly(:once).with(user.id)
    end

    it "enqueues the Reactions::UpdateReactableJob" do
      expect do
        create(:reaction, reactable: article, user: user)
      end.to have_enqueued_job(Reactions::UpdateReactableJob).exactly(:once)
    end

    it "enqueues the Reactions::BustReactableCacheJob" do
      expect do
        create(:reaction, reactable: article, user: user)
      end.to have_enqueued_job(Reactions::BustReactableCacheJob).exactly(:once)
    end

    it "enqueues the Reactions::BustHomepageCacheJob" do
      expect do
        create(:reaction, reactable: article, user: user)
      end.to have_enqueued_job(Reactions::BustHomepageCacheJob).exactly(:once)
    end
  end

  context "when creating and performing jobs" do
    it "updates the reactable Comment" do
      perform_enqueued_jobs do
        updated_at = 1.day.ago
        comment = create(:comment, commentable: article, updated_at: updated_at)
        create(:reaction, reactable: comment, user: user)
        expect(comment.reload.updated_at).to be > updated_at
      end
    end

    it "touches the user" do
      perform_enqueued_jobs do
        updated_at = 1.day.ago
        user.update_columns(updated_at: updated_at)
        create(:reaction, reactable: article, user: user)
        expect(user.reload.updated_at).to be > updated_at
      end
    end
  end
end
