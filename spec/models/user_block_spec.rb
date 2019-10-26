require "rails_helper"

RSpec.describe UserBlock, type: :model do
  let(:blocker) { create(:user) }
  let(:blocked) { create(:user) }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:config).in_array(%w[default]) }

    it "prevents the blocker from blocking itself" do
      user_block = UserBlock.new(blocker_id: 1, blocked_id: 1, config: "default")
      expect(user_block.valid?).to eq false
      expect(user_block.errors.full_messages).to include "Blocker can't be the same as the blocked_id"
    end
  end
end
