require "rails_helper"

RSpec.describe AudienceSegmentRefreshAllWorker, type: :worker do
  let(:worker) { subject }
  let(:approved_and_published_ad) do
    create(:billboard,
           approved: true,
           published: true,
           audience_segment: create(:audience_segment))
  end

  before do
    allow(AudienceSegmentRefreshWorker).to receive(:perform_bulk)
    create(:billboard,
           approved: false,
           published: true,
           audience_segment: create(:audience_segment))
    create(:billboard,
           approved: true,
           published: false,
           audience_segment: create(:audience_segment))
    create(:billboard,
           approved: false,
           published: false,
           audience_segment: create(:audience_segment))

    create(:billboard,
           approved: true,
           published: true,
           audience_segment: approved_and_published_ad.audience_segment)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  it "refreshes all active ads' segments" do
    worker.perform
    # NOTE: `perform_bulk` takes an array of arrays as argument.
    expect(AudienceSegmentRefreshWorker).to have_received(:perform_bulk)
      .with([[approved_and_published_ad.audience_segment_id]])
  end
end
