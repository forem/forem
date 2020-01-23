require "rails_helper"

RSpec.describe ProMemberships::PopulateHistoryWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:user) { create(:user, :pro) }

    before do
      allow(User).to receive(:find_by).and_return(user)
      allow(user.page_views).to receive(:reindex!)
    end

    it "indexes user page views" do
      described_class.new.perform(user.id)
      expect(user.page_views).to have_received(:reindex!).once
    end
  end
end
