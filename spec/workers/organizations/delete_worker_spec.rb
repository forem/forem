require "rails_helper"

RSpec.describe Organizations::DeleteWorker, type: :worker do
  let(:worker) { subject }

  describe "#perform" do
    let!(:org) { create(:organization) }
    let!(:user) { create(:user) }
    let(:delete) { Organizations::Delete }

    context "when org and user are found" do
      it "destroys the org" do
        worker.perform(org.id, user.id)
        expect(Organization.exists?(id: org.id)).to be(false)
      end

      it "calls the service" do
        allow(delete).to receive(:call)
        worker.perform(org.id, user.id)
        expect(delete).to have_received(:call).with(org)
      end

      it "touches the user" do
        allow(User).to receive(:find_by) { user }
        allow(user).to receive(:touch)
        worker.perform(org.id, user.id)
        expect(user).to have_received(:touch).with(:organization_info_updated_at)
      end

      it "busts user's cache" do
        bust_cache = EdgeCache::BustUser
        allow(bust_cache).to receive(:call)
        worker.perform(org.id, user.id)
        expect(bust_cache).to have_received(:call).with(user)
      end
    end

    context "when an org or a user is not found" do
      it "doesn't fail" do
        worker.perform(-1, -1)
      end
    end
  end
end
