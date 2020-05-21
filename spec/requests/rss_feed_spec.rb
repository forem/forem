require "rails_helper"

RSpec.describe "RssFeed", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:tag) { FactoryBot.create(:tag) }
  let(:base_url) { "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}" }

  before do
    FactoryBot.create(:article, user_id: user.id, featured: true)
    FactoryBot.create(:article, tags: tag.name, featured: true)
  end

  describe "GET query page" do
    it "renders feed" do
      get "/feed"
      expect(response.body).to include("<link>#{base_url}</link>")
    end

    it "renders user feed" do
      get "/feed/#{user.username}"
      expect(response.body).to include("<link>#{base_url}/#{user.username}</link>")
    end

    it "renders organization feed" do
      create(:article, organization_id: organization.id)
      get "/feed/#{organization.slug}"
      expect(response.body).to include("<link>#{base_url}/#{organization.slug}</link>")
    end

    it "renders tag feed" do
      get "/feed/tag/#{tag.name}"
      expect(response.body).to include("<link>#{base_url}</link>")
    end
  end
end
