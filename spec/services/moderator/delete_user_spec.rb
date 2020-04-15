require "rails_helper"

RSpec.describe Moderator::DeleteUser, type: :service do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  describe "delete_user" do
    it "deletes user" do
      sidekiq_perform_enqueued_jobs do
        described_class.call(user: user, admin: admin, user_params: {})
      end
      expect(User.find_by(id: user.id)).to be_nil
    end

    it "deletes user's follows" do
      create(:follow, follower: user)
      create(:follow, followable: user)

      expect do
        sidekiq_perform_enqueued_jobs do
          described_class.call(user: user, admin: admin, user_params: {})
        end
      end.to change(Follow, :count).by(-2)
    end

    it "deletes user's articles" do
      article = create(:article, user: user)
      sidekiq_perform_enqueued_jobs do
        described_class.call(user: user, admin: admin, user_params: {})
      end
      expect(Article.find_by(id: article.id)).to be_nil
    end
  end

  describe "#ghostify" do
    let(:deleter) { described_class.new(user: user, admin: admin, user_params: { ghostify: true }) }

    before do
      user.update(username: "ghost")
      create(:article, user: user)
    end

    it "reassigns articles" do
      allow(deleter).to receive(:reassign_articles)
      deleter.ghostify
      expect(deleter).to have_received(:reassign_articles)
    end

    it "reassigns comments" do
      allow(deleter).to receive(:reassign_comments)
      deleter.ghostify
      expect(deleter).to have_received(:reassign_comments)
    end
  end
end
