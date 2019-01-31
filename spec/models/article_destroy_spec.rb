require "rails_helper"

RSpec.describe Article, type: :model do
  before do
    Delayed::Worker.delay_jobs = true
  end

  after do
    Delayed::Worker.delay_jobs = false
  end

  context "when no organization" do
    let(:article) { create(:article) }

    before { create(:reaction, reactable: article) }

    it "doesn't create ScoreCalcJob on destroy" do
      allow(Articles::ScoreCalcJob).to receive(:perform_later)
      expect(Articles::ScoreCalcJob).not_to have_received(:perform_later)
    end
  end

  context "with organization" do
    let(:organization) { create(:organization) }
    let!(:article) { create(:article, organization: organization) }
    let!(:another_article) { create(:article, organization: organization) }

    it "creates Articles::ResaveJob for organization articles on destroy" do
      allow(Articles::ResaveJob).to receive(:perform_later)
      article.destroy
      expect(Articles::ResaveJob).to have_received(:perform_later).with([another_article.id])
    end
  end
end
