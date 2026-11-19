require "rails_helper"

RSpec.describe RefreshLiquidEmbedRecordsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", ["Article", [1]]

  it "refreshes the given records through UpdateDependentEmbedsWorker" do
    refresher = instance_double(Articles::UpdateDependentEmbedsWorker, refresh_records: nil)
    allow(Articles::UpdateDependentEmbedsWorker).to receive(:new).and_return(refresher)

    described_class.new.perform("Article", [1, 2])

    expect(refresher).to have_received(:refresh_records).with("Article", [1, 2])
  end

  it "ignores unsupported record types" do
    allow(Articles::UpdateDependentEmbedsWorker).to receive(:new)

    described_class.new.perform("User", [1])

    expect(Articles::UpdateDependentEmbedsWorker).not_to have_received(:new)
  end
end
