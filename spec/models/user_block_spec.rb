require "rails_helper"

RSpec.describe UserBlock, type: :model do
  let(:blocker) { create(:user) }
  let(:blocked_user) { create(:user) }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:config).in_array(%w[default]) }

    it "prevents the blocker from blocking itself" do
      user_block = build(:user_block, blocker: blocker, blocked: blocker, config: "default")
      expect(user_block).not_to be_valid
      expect(user_block.errors.full_messages).to include("Blocker can't be the same as the blocked_id")
    end

    it "returns ids blocked by user" do
      create(:user_block, blocker: blocker, blocked: blocked_user, config: "default")
      expect(described_class.cached_blocked_ids_for_blocker(blocker)).to eq([blocked_user.id])
    end

    it "busts user block cache" do
      allow(Rails.cache).to receive(:delete).and_call_original
      block = create(:user_block, blocker: blocker, blocked: blocked_user, config: "default")
      expect(Rails.cache).to have_received(:delete).with("blocked_ids_for_blocker/#{blocker.id}").once
      block.destroy
      expect(Rails.cache).to have_received(:delete).with("blocked_ids_for_blocker/#{blocker.id}").twice
    end
  end
end
