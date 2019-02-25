require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:user) { create(:user) }
  # let!(:reaction) { build(:reaction, reactable: article) }

  context "when creating and enqueueing" do
    before { ActiveJob::Base.queue_adapter = :test }

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

  context "when creating and inline" do
    before { ActiveJob::Base.queue_adapter = :inline }

    it "updates the reactable Comment" do
      comment = create(:comment, commentable: article)
      comment.update_columns(updated_at: Time.now - 1.day)
      now = Time.now
      create(:reaction, reactable: comment, user: user)
      comment.reload
      expect(comment.updated_at).to be >= now
    end

    it "touches the user" do
      user.update_columns(updated_at: Time.now - 1.day)
      now = Time.now
      create(:reaction, reactable: article, user: user)
      user.reload
      expect(user.updated_at).to be >= now
    end
  end
end
