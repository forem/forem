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

    it "sets remember_me for the new user" do
      user = service.get_user
      user.reload
      expect(user.remember_me).to be_truthy
      expect(user.remember_token).to be_truthy
      expect(user.remember_created_at).to be_truthy
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
  end
end
