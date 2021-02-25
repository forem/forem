require "rails_helper"

describe Loggers::LogWorkerQueueStats, type: :service do
  it "logs totals" do
    allow(described_class).to receive(:record_totals)
    described_class.call
    expect(described_class).to have_received(:record_totals)
  end

  it "logs queue stats" do
    allow(described_class).to receive(:record_queue_stats)
    described_class.call
    expect(described_class).to have_received(:record_queue_stats)
  end
end
