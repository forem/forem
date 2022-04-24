require "rails_helper"

RSpec.describe Spaces::BustCachesForSpaceChangeWorker, type: :worker do
  let(:worker) { subject }

  before { allow(Rails.cache).to receive(:delete_matched).and_call_original }

  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  it "deletes matched cache keys" do
    worker.perform
    expect(Rails.cache).to have_received(:delete_matched)
  end
end
