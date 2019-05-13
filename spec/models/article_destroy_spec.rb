require "rails_helper"

RSpec.describe Article, type: :model do
  context "when no organization" do
    let(:article) { create(:article) }

    before { create(:reaction, reactable: article) }

    it "doesn't create ScoreCalcJob on destroy" do
      expect { article.destroy }.not_to have_enqueued_job(Articles::ScoreCalcJob)
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
      expect do
        article.destroy
      end.to have_enqueued_job(Articles::BustMultipleCachesJob).exactly(:once).
        with([user_article.id, org_user_article.id, org_article.id].sort)
    end
  end
end
