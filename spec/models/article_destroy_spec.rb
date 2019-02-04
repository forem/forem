require "rails_helper"

RSpec.describe Article, type: :model do
  before { ActiveJob::Base.queue_adapter = :test }

  context "when no organization" do
    let(:article) { create(:article) }

    before { create(:reaction, reactable: article) }

    it "doesn't create ScoreCalcJob on destroy" do
      expect { article.destroy }.not_to have_enqueued_job(Articles::ScoreCalcJob)
    end
  end

  context "with organization" do
    let(:organization) { create(:organization) }
    let!(:article) { create(:article, organization: organization) }

    before { create(:article, organization: organization) }

    it "creates Articles::ResaveJob for organization articles on destroy" do
      expect { article.destroy }.to have_enqueued_job(Articles::ResaveJob).exactly(:once)
    end
  end
end
