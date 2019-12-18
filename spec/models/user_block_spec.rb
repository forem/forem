require "rails_helper"

RSpec.describe UserBlock, type: :model do
  let(:blocker) { build(:user) }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:config).in_array(%w[default]) }

    it "prevents the blocker from blocking itself" do
      user_block = build(:user_block, blocker: blocker, blocked: blocker, config: "default")
      expect(user_block).not_to be_valid
      expect(user_block.errors.full_messages).to include("Blocker can't be the same as the blocked_id")
    end
  end
end
