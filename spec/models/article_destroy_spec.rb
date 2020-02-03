require "rails_helper"

RSpec.describe Article, type: :model do
  context "when no organization" do
    let(:article) { create(:article) }

    before { create(:reaction, reactable: article) }

    it "doesn't create ScoreCalcWorker on destroy" do
      sidekiq_assert_no_enqueued_jobs(only: Articles::ScoreCalcWorker) do
        article.destroy
      end
    end
  end

  context "with organization" do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }
    let!(:article) { create(:article, organization: organization, user: user) }
    let!(:org_article) { create(:article, organization: organization) }
    let!(:user_article) { create(:article, user: user) }
    let!(:org_user_article) { create(:article, user: user, organization: organization) }

    it "queues BustCacheJob with user and organization article_ids" do
      sidekiq_assert_enqueued_with(job: Articles::BustMultipleCachesWorker, args: [[user_article.id, org_user_article.id, org_article.id].sort]) do
        article.destroy
      end
    end
  end
end
