require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:article) { create(:article, featured: true) }
  let!(:reaction) { create(:reaction, reactable: article) }

  it "creates a ScoreCalcJob on article reaction destroy" do
    ActiveJob::Base.queue_adapter = :test
    expect { reaction.destroy }.to have_enqueued_job(Articles::ScoreCalcJob).exactly(:once)
  end
end
