require "rails_helper"

RSpec.describe Users::FollowWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:followable) { create(:user) }
    let(:invalid_id) { -1 }
    let(:worker) { subject }

    context "when followable doesn't exist" do
      it "doesn't follow user" do
        expect do
          worker.perform(user.id, invalid_id, followable.class.name)
        end.not_to change(Follow, :count)
      end
    end

    context "when user doesn't exist" do
      it "doesn't follow user" do
        expect do
          worker.perform(invalid_id, followable.id, followable.class.name)
        end.not_to change(Follow, :count)
      end
    end

    context "when user + followable exist" do
      it "doesn't follow user with unexpected type" do
        expect do
          worker.perform(user.id, followable.id, "Article")
        end.not_to change(Follow, :count)
      end

      it "follows user" do
        expect do
          worker.perform(user.id, followable.id, followable.class.name)
        end.to change(Follow, :count).by(1)
      end
    end
  end
end
