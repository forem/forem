require "rails_helper"

RSpec.describe Moderator::BanishUserWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  # TODO: Remove this test because BanihedUser already covers it
  describe "#perform" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:admin) { create(:user, :super_admin) }

    before do
      profile_field = create(:profile_field, label: "Test field")
      attr_name = profile_field.attribute_name
      user.profile.update!(attr_name => "text is here")
      create(:article, user_id: user.id)
      create(:article, user_id: user.id)
      create(:listing, user: user)
      user.follow(user2)
      described_class.new.perform(admin.id, user.id)
      user.reload
    end

    it "makes user suspended and username spam" do
      expect(user.username).to include("spam")
      expect(user.suspended?).to be true
    end

    it "deletes user content" do
      expect(user.reactions.count).to eq(0)
      expect(user.comments.count).to eq(0)
      expect(user.articles.count).to eq(0)
      expect(user.follows.count).to eq(0)
      expect(user.listings.count).to eq(0)
    end

    it "reassigns profile info" do
      attr_name = ProfileField.find_by(label: "Test field").attribute_name
      expect(user.profile.public_send(attr_name)).to be_blank
    end

    it "creates an entry in the BanishedUsers table" do
      expect(BanishedUser.all.size).to be 1
    end

    it "records who banished a user" do
      expect(BanishedUser.last.banished_by).to eq admin
    end
  end
end
