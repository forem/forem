require "rails_helper"

RSpec.describe DiscussionLock do
  let(:discussion_lock) { create(:discussion_lock) }

  describe "relationships" do
    it { is_expected.to belong_to(:article) }
    it { is_expected.to belong_to(:locking_user) }
  end

  describe "validations" do
    subject { discussion_lock }

    it { is_expected.to validate_uniqueness_of(:article_id) }

    it "sanitizes attributes before validation", :aggregate_failures do
      discussion_lock = described_class.new(notes: "", reason: " ")

      discussion_lock.validate

      expect(discussion_lock.notes).to be_nil
      expect(discussion_lock.reason).to be_nil
    end
  end
end
