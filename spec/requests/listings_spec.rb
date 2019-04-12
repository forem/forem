require "rails_helper"

RSpec.describe "/listings", type: :request do

  describe "GETS /listings" do
    it "has page content" do
      get "/listings"
      expect(response.body).to include("classified-filters")
    end
    it "has page content for category page" do
      get "/listings/saas"
      expect(response.body).to include("classified-filters")
    end
  end
  describe "GETS /listings/new" do
    it "has page content" do
      get "/listings"
      expect(response.body).to include("classified-filters")
    end
  end

  describe "POST /listings" do
    before do
      user = create(:user)
      20.times do 
        create(:credit, user_id: user.id)
      end
      sign_in user
    end
    it "creates proper listing if credits are available" do
      post "/listings", params: { classified_listing: {
        title: "Hey", category: "saas", body_markdown: "hey hey my my"
      }}
      expect(ClassifiedListing.last.processed_html).to include("hey my")
    end
    it "spends credits" do
      num_credits = Credit.where(spent: true).size
      post "/listings", params: { classified_listing: {
        title: "Hey", category: "saas", body_markdown: "hey hey my my"
      }}
      expect(Credit.where(spent: true).size).to be > num_credits
    end
    it "adds tags" do
      num_credits = Credit.where(spent: true).size
      post "/listings", params: { classified_listing: {
        title: "Hey", category: "saas", body_markdown: "hey hey my my", tag_list: "ruby, rails, go"
      }}
      expect(ClassifiedListing.last.cached_tag_list).to include("rails")
    end
  end
end