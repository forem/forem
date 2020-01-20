require "rails_helper"

RSpec.describe Reactions::CreateWorker, type: :worker do
  describe "#perform" do
    let(:reactable_type) { "Comment" }
    let(:user_id) { 8 }
    let(:reactable_id) { 1 }
    let(:category) { "like" }
    let(:worker) { subject }

    context "when no user found" do
      before do
        allow(User).to receive(:find_by)
        allow(Reaction).to receive(:create)
      end

      it "does not create a reaction" do
        worker.perform(user_id, reactable_id, reactable_type, category)
        expect(Reaction).not_to have_received(:create)
      end
    end

    context "when no reactable found" do
      before do
        allow(reactable_type.constantize).to receive(:find_by)
        allow(Reaction).to receive(:create)
      end

      it "does not create a reaction" do
        worker.perform(user_id, reactable_id, reactable_type, category)
        expect(Reaction).not_to have_received(:create)
      end
    end

    context "when user + reactable" do
      let(:user) { create(:user) }
      let(:reactable) { create(:comment, commentable: create(:article)) }

      it "calls the service" do
        allow(Reaction).to receive(:create!).with(user: user, reactable: reactable, category: "like")
        worker.perform(user.id, reactable.id, reactable_type, category)
        expect(Reaction).to have_received(:create!).with(user: user, reactable: reactable, category: "like")
      end

      it "creates a reaction" do
        expect do
          worker.perform(user.id, reactable.id, reactable_type, category)
        end.to change(Reaction, :count).by(1)
      end
    end
  end
end
