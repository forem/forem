require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:user) { create(:user) }
  # let!(:reaction) { build(:reaction, reactable: article) }

  context "when creating and inline" do
    before { ActiveJob::Base.queue_adapter = :inline }

    it "updates the reactable Article" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        run_background_jobs_immediately do
          create(:reaction, reactable: article, user: user)
        end
      end.to have_enqueued_job(Articles::ScoreCalcJob).exactly(:once).with(article.id)
    end

    it "updates the reactable Comment" do
      comment = create(:comment, commentable: article)
      comment.update_columns(updated_at: Time.now - 1.day)
      now = Time.now
      run_background_jobs_immediately do
        create(:reaction, reactable: comment, user: user)
      end
      comment.reload
      expect(comment.updated_at).to be >= now
    end

    it "busts the reactable cache" do
      reaction = build(:reaction, reactable: article)
      buster = double
      allow(buster).to receive(:bust)
      allow(reaction).to receive(:cache_buster).and_return(buster)
      run_background_jobs_immediately do
        reaction.save
      end
      expect(buster).to have_received(:bust).at_least(:twice)
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
