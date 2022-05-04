require "rails_helper"

RSpec.describe Users::RecordFieldTestEventWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1
  include FieldTest::Helpers

  describe "#perform" do
    let(:worker) { subject }
    let(:goal) { "try_to_takeover_the_world" }

    before do
      allow(AbExperiment).to receive(:register_conversions_for).and_call_original
    end

    context "with a non-existent user" do
      let(:user_id) { nil }

      it "gracefully exits" do
        worker.perform(user_id, goal)
        expect(AbExperiment).not_to have_received(:register_conversions_for)
      end
    end

    context "with a user" do
      let(:user) { create(:user) }
      let(:user_id) { user.id }

      it "forward delegates to AbExperiment" do
        worker.perform(user_id, goal)
        expect(AbExperiment).to have_received(:register_conversions_for).with(user: user, goal: goal)
      end
    end
  end
end
