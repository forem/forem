require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:article) { create(:article, featured: true) }
  let!(:reaction) { build(:reaction, reactable: article) }

  before do
    Delayed::Worker.delay_jobs = true
  end

  after do
    Delayed::Worker.delay_jobs = false
  end

  it "creates a ScoreCalcJob on article reaction destroy" do
    expect do
      reaction.destroy
    end.to change(Delayed::Job.where(queue: "articles_score_calc"), :count).by(1)
  end
end
