require "rails_helper"

RSpec.describe DataFixes::RunWorker, type: :worker do
  describe "#perform" do
    let(:worker) { described_class.new }

    it "runs the requested data fix" do
      allow(DataFixes::Runner).to receive(:call)

      worker.perform(DataFixes::FixTagCounts::KEY, 123)

      expect(DataFixes::Runner).to have_received(:call).with(DataFixes::FixTagCounts::KEY)
    end

    it "reports failures and re-raises errors" do
      error = StandardError.new("boom")
      allow(DataFixes::Runner).to receive(:call).and_raise(error)
      allow(Honeybadger).to receive(:notify)

      expect { worker.perform(DataFixes::FixTagCounts::KEY, 123) }.to raise_error(StandardError, "boom")

      expect(Honeybadger).to have_received(:notify).with(
        error,
        context: { data_fix: DataFixes::FixTagCounts::KEY, requested_by_user_id: 123 },
      )
    end
  end
end
