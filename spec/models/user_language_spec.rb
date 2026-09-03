require "rails_helper"

RSpec.describe UserLanguage do
  describe "validations" do
    subject { build(:user_language) }

    describe "builtin validations" do
      it { is_expected.to belong_to(:user) }
      it { is_expected.to validate_presence_of(:language) }
    end

    it "actually validates language" do
      expect(build(:user_language, language: :es)).to be_valid
    end

    it "actually validates language (invalid)" do
      lang = build(:user_language, language: :abracadabra)
      expect(lang).not_to be_valid
      expect(lang.errors[:language]).to be_present
    end
  end

  describe "caching" do
    let(:user) { create(:user) }
    let(:cache_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    around do |example|
      original_cache = Rails.cache
      Rails.cache = cache_store
      example.run
      Rails.cache = original_cache
    end

    it "caches user languages and clears cache after commit" do
      create(:user_language, user: user, language: "en")
      expect(user.cached_languages).to eq(["en"])

      # Should be cached
      expect(Rails.cache.exist?("user-#{user.id}/languages")).to be true

      # Creating another language clears the cache
      create(:user_language, user: user, language: "es")
      expect(Rails.cache.exist?("user-#{user.id}/languages")).to be false
      expect(user.cached_languages).to contain_exactly("en", "es")
    end
  end
end
