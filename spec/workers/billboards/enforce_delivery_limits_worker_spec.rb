require "rails_helper"

RSpec.describe Billboards::EnforceDeliveryLimitsWorker, type: :worker do
  it "delegates to Billboards::EnforceDeliveryLimits.sweep!" do
    allow(Billboards::EnforceDeliveryLimits).to receive(:sweep!).and_return([])

    described_class.new.perform

    expect(Billboards::EnforceDeliveryLimits).to have_received(:sweep!).once
  end

  it "is configured with coalescing lock options on the low_priority queue", :aggregate_failures do
    options = described_class.get_sidekiq_options
    expect(options["queue"]).to eq(:low_priority)
    expect(options["lock"]).to eq(:until_executing)
    expect(options["on_conflict"]).to eq(:replace)
  end
end
