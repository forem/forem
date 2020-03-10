require "rails_helper"

RSpec.describe FieldTests::PruneOldExperimentsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1
  include FieldTest::Helpers

  describe "#perform" do
    let(:worker) { subject }

    it "prunes first 5% of memberships and events" do
      create_list(:user, 40)
      User.all.each do |user|
        create(:field_test_memberships, participant_id: user.id.to_s)
        field_test_converted(:user_home_feed, participant: user, goal: "user_creates_comment")
      end
      worker.perform
      expect(FieldTest::Membership.count).to be(38)
      expect(FieldTest::Event.count).to be(38)
      expect(FieldTest::Event.pluck(:field_test_membership_id).sort).to eq(FieldTest::Membership.pluck(:id).sort)
    end
  end
end
