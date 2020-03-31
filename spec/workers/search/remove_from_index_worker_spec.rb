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

    it "doesn't raise an error if key is missing" do
      # key is nil
      expect { worker.perform("searchables_#{Rails.env}", nil) }.not_to raise_error
    end

    it "doesn't raise an error if index is missing" do
      # index is nil
      expect { worker.perform(nil, "users-456") }.not_to raise_error
    end
  end
end
