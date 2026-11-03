require "rails_helper"

RSpec.describe ApiSecret do
  describe "validations" do
    subject { build(:api_secret, user: build_stubbed(:user)) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(300) }

    it "validates the number of keys a user already has", :aggregate_failures do
      user = create(:user)
      now = Time.current
      described_class.insert_all!(
        Array.new(10) do |i|
          {
            user_id: user.id,
            description: "Key #{i}",
            secret: "secret_token_#{i}",
            created_at: now,
            updated_at: now
          }
        end,
      )
      invalid_secret = build(:api_secret, user: user)

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
