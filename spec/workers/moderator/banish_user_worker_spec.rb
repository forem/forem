require "rails_helper"

RSpec.describe Moderator::BanishUserWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:user) { create(:user, currently_hacking_on: "text is here") }
    let(:user2) { create(:user) }
    let(:admin) { create(:user, :super_admin) }

    before do
      create(:article, user_id: user.id)
      create(:article, user_id: user.id)
      create(:listing, user: user)
      ChatChannels::CreateWithUsers.call(users: [user, user2])
      user.follow(user2)
      described_class.new.perform(admin.id, user.id)
      user.reload
    end

    it "makes user banned and username spam" do
      expect(user.username).to include("spam")
      expect(user.has_role?(:banned)).to be true
    end

    it "deletes user content" do
      expect(user.reactions.count).to eq(0)
      expect(user.comments.count).to eq(0)
      expect(user.articles.count).to eq(0)
      expect(user.chat_channels.count).to eq(0)
      expect(user.follows.count).to eq(0)
      expect(user.listings.count).to eq(0)
    end

    it "reassigns profile info" do
      expect(user.currently_hacking_on).to be_blank
    end

    it "creates an entry in the BanishedUsers table" do
      expect(BanishedUser.all.size).to be 1
    end

    it "records who banished a user" do
      expect(BanishedUser.last.banished_by).to eq admin
    end
  end
end
