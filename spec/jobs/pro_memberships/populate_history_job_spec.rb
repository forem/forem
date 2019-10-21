require "rails_helper"

RSpec.describe ProMemberships::PopulateHistoryJob, type: :job do
  include_examples "#enqueues_job", "pro_memberships_populate_history", 1

  describe "#perform_now" do
    let(:user) { create(:user, :pro) }

    before do
      allow(User).to receive(:find_by).and_return(user)
      allow(user.page_views).to receive(:reindex!)
    end

    it "indexes user page views" do
      described_class.perform_now(user.id)
      expect(user.page_views).to have_received(:reindex!).once
    end
  end
end
