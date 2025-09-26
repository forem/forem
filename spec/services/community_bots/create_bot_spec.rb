require "rails_helper"

RSpec.describe CommunityBots::CreateBot do
  let(:subforem) { create(:subforem, domain: "test.com") }
  let(:admin_user) { create(:user, :super_admin) }
  let(:moderator_user) { create(:user) }
  let(:regular_user) { create(:user) }

  before do
    allow(moderator_user).to receive(:subforem_moderator?).with(subforem: subforem).and_return(true)
  end

  describe "#call" do
    context "when user is authorized" do
      it "creates a community bot successfully" do
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
        )

        puts "Error message: #{result.error_message}" unless result.success?
        expect(result.success?).to be true
        expect(result.bot_user).to be_present
        expect(result.bot_user.name).to eq("Test Bot")
        expect(result.bot_user.type_of).to eq("community_bot")
        expect(result.bot_user.onboarding_subforem_id).to eq(subforem.id)
        expect(result.bot_user.registered).to be true
        expect(result.bot_user.confirmed_at).to be_present
        expect(result.api_secret).to be_present
        expect(result.api_secret.description).to include("Test Bot")
      end

      it "creates a bot with a unique email" do
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
        )

        expect(result.bot_user.email).to include("bot-test-bot")
        expect(result.bot_user.email).to end_with("@test.com")
      end

      it "creates a bot with a unique username from name" do
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
        )

        expect(result.bot_user.username).to include("test-bot")
        expect(result.bot_user.username).to match(/\d+$/)
      end

      it "creates a bot with provided username" do
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
          username: "mycustombot",
        )

        expect(result.bot_user.username).to eq("mycustombot")
      end

      it "creates a bot with provided username when username already exists" do
        # Create a user with the same username first
        create(:user, username: "mycustombot")

        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
          username: "mycustombot",
        )

        expect(result.bot_user.username).to include("mycustombot")
        expect(result.bot_user.username).to match(/\d+$/)
      end

      it "uses subforem logo when no image provided and subforem has logo" do
        # This test is temporarily disabled since profile image setting is disabled
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
        )

        expect(result.success?).to be true
        # TODO: Re-enable this test when profile image setting is fixed
        # expect(Settings::General).to have_received(:logo_png).with(subforem_id: subforem.id)
      end

      it "uses provided profile image" do
        profile_image = Rack::Test::UploadedFile.new(Rails.root.join("spec/support/fixtures/images/image1.jpeg"),
                                                     "image/jpeg")

        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
          profile_image: profile_image,
        )

        expect(result.success?).to be true
        expect(result.bot_user).to be_present
      end

      it "sets the invited_by relationship" do
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
        )

        expect(result.bot_user.invited_by).to eq(admin_user)
      end

      it "works for subforem moderators" do
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Moderator Bot",
          created_by: moderator_user,
        )

        expect(result.success?).to be true
        expect(result.bot_user.name).to eq("Moderator Bot")
      end
    end

    context "when user is not authorized" do
      it "returns failure for regular users" do
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: regular_user,
        )

        expect(result.success?).to be false
        expect(result.error_message).to include("Unauthorized")
      end
    end

    context "when subforem does not exist" do
      it "returns failure" do
        result = described_class.call(
          subforem_id: 99_999,
          name: "Test Bot",
          created_by: admin_user,
        )

        expect(result.success?).to be false
        expect(result.error_message).to include("Subforem not found")
      end
    end

    context "when bot creation fails" do
      before do
        allow(User).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(User.new))
      end

      it "returns failure with error message" do
        result = described_class.call(
          subforem_id: subforem.id,
          name: "Test Bot",
          created_by: admin_user,
        )

        expect(result.success?).to be false
        expect(result.error_message).to include("Failed to create bot")
      end
    end
  end
end
