require "rails_helper"

RSpec.describe AuthorizationService, type: :service do
  before { mock_auth_hash }

  describe "new user" do
    let(:auth) { OmniAuth.config.mock_auth[:github] }
    let!(:service) { described_class.new(auth) }

    it "creates a new user" do
      expect do
        service.get_user
      end.to change(User, :count).by(1)
    end

    it "sets remember_me for the new user" do
      user = service.get_user
      user.reload
      expect(user.remember_me).to be_truthy
      expect(user.remember_token).to be_truthy
      expect(user.remember_created_at).to be_truthy
    end

    it "queues a slack message to be sent for a user whose identity is brand new" do
      service.auth.extra.raw_info.created_at = 1.minute.ago.rfc3339

      sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
        service.get_user
      end
    end
  end

  describe "existing user" do
    let(:auth) { OmniAuth.config.mock_auth[:twitter] }
    let(:user) { create(:user) }

    before { OmniAuth.config.mock_auth[:twitter].info.email = user.email }

    it "doesn't create a duplicate user" do
      service = described_class.new(auth)
      expect do
        service.get_user
      end.not_to change(User, :count)
    end

    it "sets remember_me for the existing user" do
      user.update_columns(remember_token: nil, remember_created_at: nil)
      service = described_class.new(auth)
      service.get_user
      user.reload
      expect(user.remember_me).to be_truthy
      expect(user.remember_token).to be_truthy
      expect(user.remember_created_at).to be_truthy
    end

    context "when the user has a new Twitter username" do
      it "updates their username properly" do
        new_username = "new_username#{rand(1000)}"
        auth.info.nickname = new_username
        service = described_class.new(auth)
        service.get_user
        user.reload
        expect(user.twitter_username).to eq new_username
      end

      it "touches the profile_updated_at timestamp" do
        original_profile_updated_at = user.profile_updated_at
        new_username = "new_username#{rand(1000)}"
        auth.info.nickname = new_username
        service = described_class.new(auth)
        service.get_user
        user.reload
        expect(user.profile_updated_at).to be > original_profile_updated_at
      end
    end
  end
end
