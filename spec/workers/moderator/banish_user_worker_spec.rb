require "rails_helper"

RSpec.describe Moderator::BanishUserWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:user) { create(:user) }
    let(:admin) { create(:user, :super_admin) }

    it "makes user banned and username spam" do
      described_class.new.perform(admin.id, user.id)
      user.reload
      expect(user.username).to include("spam")
      expect(user.has_role?(:banned)).to be true
    end

    it "deletes user articles" do
      create(:article, user_id: user.id)
      create(:article, user_id: user.id)
      described_class.new.perform(admin.id, user.id)
      user.reload
      expect(user.articles.size).to be 0
    end
  end
end
