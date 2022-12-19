require "rails_helper"

RSpec.describe ApiSecret, type: :model do
  describe "validations" do
    subject { create(:api_secret) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(300) }

    it "validates the number of keys a user already has" do
      user = create(:user)
      create_list(:api_secret, 9, user_id: user.id)
      invalid_secret = create(:api_secret, user_id: user.id)

      expect(invalid_secret).not_to be_valid
      expect(invalid_secret.errors.full_messages.join).to include("limit of 10 per user has been reached")
    end
  end

  describe "Rack::Attack cache invalidation optimization" do
    before do
      cache_db = ActiveSupport::Cache.lookup_store(:redis_cache_store)
      allow(Rails).to receive(:cache) { cache_db }

      allow(Rails.cache).to receive(:delete)
      allow(Rails.cache).to receive(:delete)
        .with(Rack::Attack::ADMIN_API_CACHE_KEY)
    end

    context "when ApiSecret is created" do
      it "clears the cache if it belongs to an admin" do
        create(:api_secret, user: create(:user, :admin))
        expect(Rails.cache).to have_received(:delete)
          .with(Rack::Attack::ADMIN_API_CACHE_KEY)
      end

      it "doesn't clear the cache if it belongs to an admin" do
        create(:api_secret)
        expect(Rails.cache).not_to have_received(:delete)
          .with(Rack::Attack::ADMIN_API_CACHE_KEY)
      end
    end
  end
end
