require "rails_helper"

RSpec.describe Search::RemoveFromIndexWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority", ["searchables_#{Rails.env}", "users-456"]

  describe "#perform" do
    let(:algolia_index) { instance_double(Algolia::Index) }

    before do
      allow(Algolia::Index).to receive(:new).and_return(algolia_index)
      allow(algolia_index).to receive(:delete_object)
    end

    it "calls the service" do
      worker.perform("searchables_#{Rails.env}", "users-456")

      expect(algolia_index).to have_received(:delete_object).with("users-456").once
    end

    it "does nothing if key is missing" do
      # key is nil
      worker.perform("searchables_#{Rails.env}", nil)

      expect(algolia_index).not_to have_received(:delete_object)
    end

    it "does nothing if index is missing" do
      # index is nil
      worker.perform(nil, "users-456")

      expect(Algolia::Index).not_to have_received(:new)
    end
  end
end
