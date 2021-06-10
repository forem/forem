require "rails_helper"

RSpec.describe DiscussionLock, type: :model do
  let(:discussion_lock) { create(:discussion_lock) }

  describe "relationships" do
    it { is_expected.to belong_to(:article) }
    it { is_expected.to belong_to(:locking_user) }
  end

  describe "validations" do
    subject { discussion_lock }

    it { is_expected.to validate_presence_of(:article_id) }
    it { is_expected.to validate_presence_of(:locking_user_id) }
    it { is_expected.to validate_uniqueness_of(:article_id) }
  end
end
