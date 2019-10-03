require "rails_helper"

RSpec.describe Users::FollowJob, type: :job do
  include_examples "#enqueues_job", "users_follow", [1, 2, "User"]

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:followable) { create(:user) }
    let(:invalid_id) { -1 }

    context "when followable doesn't exist" do
      it "doesn't follow user" do
        expect do
          described_class.perform_now(user.id, invalid_id, followable.class.name)
        end.to change(Follow, :count).by(0)
      end

      it "doesn't follow user with unexpected type" do
        expect do
          described_class.perform_now(user.id, followable.id, "Article")
        end.to change(Follow, :count).by(0)
      end
    end

    context "when user doesn't exist" do
      it "doesn't follow user" do
        expect do
          described_class.perform_now(invalid_id, followable.id, followable.class.name)
        end.to change(Follow, :count).by(0)
      end
    end

    context "when user + followable exist" do
      it "follows user" do
        expect do
          described_class.perform_now(user.id, followable.id, followable.class.name)
        end.to change(Follow, :count).by(1)
      end
    end
  end
end
