require "rails_helper"
require "jobs/shared_examples/enqueues_job"

RSpec.describe Reactions::CreateJob, type: :job do
  include_examples "#enqueues_job", "reaction_create", [{ user_id: 8, reactable_id: 1, reactable_type: "Comment", category: "like" }]

  describe "#perform_now" do
    let(:reactable_type) { "Comment" }

    context "when no user found" do
      before do
        allow(User).to receive(:find_by)
        allow(Reaction).to receive(:create)
      end

      it "does not create a reaction" do
        described_class.perform_now(user_id: 8, reactable_id: 1, reactable_type: "Comment", category: "like")
        expect(Reaction).not_to have_received(:create)
      end
    end

    context "when no reactable found" do
      before do
        allow(reactable_type.constantize).to receive(:find_by)
        allow(Reaction).to receive(:create)
      end

      it "does not create a reaction" do
        described_class.perform_now(user_id: 8, reactable_id: 1, reactable_type: "Comment", category: "like")
        expect(Reaction).not_to have_received(:create)
      end
    end

    context "when user + reactable" do
      let(:user) { create(:user) }
      let(:reactable) { create(:comment, commentable: create(:article)) }

      it "calls the service" do
        allow(Reaction).to receive(:create!).with(user: user, reactable: reactable, category: "like")
        described_class.perform_now(user_id: user.id, reactable_id: reactable.id, reactable_type: reactable_type, category: "like")
        expect(Reaction).to have_received(:create!).with(user: user, reactable: reactable, category: "like")
      end

      it "creates a reaction" do
        expect do
          described_class.perform_now(user_id: user.id, reactable_id: reactable.id, reactable_type: reactable_type, category: "like")
        end.to change(Reaction, :count).by(1)
      end
    end
  end
end
