require "rails_helper"

RSpec.describe AudienceSegmentRefreshWorker, type: :worker do
  let(:worker) { subject }
  let(:fake_segment) { instance_double AudienceSegment, refresh!: :refreshed }
  let(:segment_finder) { class_double AudienceSegment }

  before do
    allow(segment_finder).to receive(:find_each).and_yield(fake_segment)
    allow(AudienceSegment).to receive(:where).and_return(segment_finder)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  it "refreshes a segment by id" do
    worker.perform([123])
    expect(AudienceSegment).to have_received(:where).with(id: [123])
    expect(fake_segment).to have_received(:refresh!)
  end

  it "refreshes segments via ids" do
    worker.perform(123, 345)
    expect(AudienceSegment).to have_received(:where).with(id: [123, 345])
    expect(fake_segment).to have_received(:refresh!)
  end
end
