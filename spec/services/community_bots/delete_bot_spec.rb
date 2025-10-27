require "rails_helper"

RSpec.describe CommunityBots::DeleteBot do
  let(:subforem) { create(:subforem) }
  let(:bot_user) { create(:user, type_of: :community_bot, onboarding_subforem_id: subforem.id) }
  let(:admin_user) { create(:user, :super_admin) }
  let(:moderator_user) { create(:user) }
  let(:regular_user) { create(:user) }

  before do
    allow(moderator_user).to receive(:subforem_moderator?).with(subforem: subforem).and_return(true)
  end

  describe "#call" do
    context "when user is authorized" do
      it "deletes a community bot successfully" do
        bot_id = bot_user.id
        
        result = described_class.call(
          bot_user: bot_user,
          deleted_by: admin_user
        )

        expect(result.success?).to be true
        expect(User.find_by(id: bot_id)).to be_nil
      end

      it "works for subforem moderators" do
        bot_id = bot_user.id
        
        result = described_class.call(
          bot_user: bot_user,
          deleted_by: moderator_user
        )

        expect(result.success?).to be true
        expect(User.find_by(id: bot_id)).to be_nil
      end
    end

    context "when user is not authorized" do
      it "returns failure for regular users" do
        result = described_class.call(
          bot_user: bot_user,
          deleted_by: regular_user
        )

        expect(result.success?).to be false
        expect(result.error_message).to include("Unauthorized")
        expect(bot_user.reload).to be_present
      end
    end

    context "when user is not a community bot" do
      let(:regular_user) { create(:user, type_of: :member) }

      it "returns failure" do
        result = described_class.call(
          bot_user: regular_user,
          deleted_by: admin_user
        )

        expect(result.success?).to be false
        expect(result.error_message).to include("User is not a community bot")
        expect(regular_user.reload).to be_present
      end
    end

    context "when bot deletion fails" do
      before do
        allow(bot_user).to receive(:destroy!).and_raise(StandardError.new("Database error"))
      end

      it "returns failure with error message" do
        result = described_class.call(
          bot_user: bot_user,
          deleted_by: admin_user
        )

        expect(result.success?).to be false
        expect(result.error_message).to include("Failed to delete bot")
        expect(result.error_message).to include("Database error")
      end
    end
  end
end
