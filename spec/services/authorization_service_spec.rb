require "rails_helper"

RSpec.describe AuthorizationService do
  before { mock_auth_hash }

  describe "new user" do
    let(:auth) { OmniAuth.config.mock_auth[:github] }
    let(:service) { described_class.new(auth) }

    it "creates a new user" do
      expect do
        service.get_user
      end.to change(User, :count).by(1)
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
