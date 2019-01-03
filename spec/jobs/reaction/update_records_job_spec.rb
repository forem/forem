require "rails_helper"

RSpec.describe Reaction::UpdateRecordsJob, type: :job do
  let(:user) { create(:user) }
  let(:reactable) { create(:article) }

  describe "#perform" do
    it "works" do
      expect { described_class.new.perform(reactable, user) }.not_to raise_error
    end
  end

  describe "#perform_later" do
    before { described_class.perform_later(reactable, user) }

    it "enqueue jobs properly" do
      expect(described_class).to have_been_enqueued
    end

    it "adds job to the :default queue" do
      expect(enqueued_jobs.last[:queue]).to eq("default")
    end
  end
end
