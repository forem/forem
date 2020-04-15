require "rails_helper"

RSpec.describe Moderator::MergeUser, type: :service do
  let!(:keep_user) { create(:user) }
  let!(:delete_user) { create(:user) }
  let(:delete_user_id) { delete_user.id }
  let(:admin) { create(:user, :super_admin) }

  describe "#merge" do
    before { sidekiq_perform_enqueued_jobs }

    it "deletes delete_user_id and keeps keep_user" do
      sidekiq_perform_enqueued_jobs do
        described_class.call_merge(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end
      expect(User.find_by(id: delete_user_id)).to be_nil
      expect(User.find_by(id: keep_user.id)).not_to be_nil
    end
  end
end
