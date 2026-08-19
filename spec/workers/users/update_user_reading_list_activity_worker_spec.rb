require "rails_helper"

RSpec.describe Users::UpdateUserReadingListActivityWorker, type: :worker do
  let(:user) { create(:user) }

  describe "#perform" do
    it "calls UserActivity.update_reading_list_articles_for with user_id" do
      expect(UserActivity).to receive(:update_reading_list_articles_for).with(user.id)
      described_class.new.perform(user.id)
    end

    it "returns early if user_id is nil" do
      expect(UserActivity).not_to receive(:update_reading_list_articles_for)
      described_class.new.perform(nil)
    end
  end
end
