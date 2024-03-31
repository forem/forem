require "rails_helper"

RSpec.describe AudienceSegmentRefreshWorker, type: :worker do
  let(:worker) { subject }
  let(:fake_segment) { instance_double AudienceSegment, refresh!: :refreshed }
  let(:segment_finder) { class_double AudienceSegment }

  before do
    allow(AudienceSegment).to receive(:find).and_return(fake_segment)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  it "refreshes a segment by id" do
    worker.perform(123)
    expect(AudienceSegment).to have_received(:find).with(123)
    expect(fake_segment).to have_received(:refresh!)
  end
end
