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
      @organization = create(:organization)
      @user = create(:user)
      20.times do 
        create(:credit, user_id: @user.id)
      end
      sign_in @user
    end
    it "creates proper listing if credits are available" do
      post "/listings", params: { classified_listing: {
        title: "Hey", category: "education", body_markdown: "hey hey my my"
      }}
      expect(ClassifiedListing.last.processed_html).to include("hey my")
    end
    it "spends credits" do
      num_credits = Credit.where(spent: true).size
      post "/listings", params: { classified_listing: {
        title: "Hey", category: "education", body_markdown: "hey hey my my"
      }}
      expect(Credit.where(spent: true).size).to be > num_credits
    end
    it "adds tags" do
      num_credits = Credit.where(spent: true).size
      post "/listings", params: { classified_listing: {
        title: "Hey", category: "education", body_markdown: "hey hey my my", tag_list: "ruby, rails, go"
      }}
      expect(ClassifiedListing.last.cached_tag_list).to include("rails")
    end
    it "creates the listing for the user" do
      @user.update(organization_id: @organization.id)
      post "/listings", params: { classified_listing: {
        title: "Hey", category: "education", body_markdown: "hey hey my my", tag_list: "ruby, rails, go",
        post_as_organization: 0
      }}
      expect(ClassifiedListing.last.organization_id).not_to eq(@organization.id)
    end
    it "creates the listing for the organization" do
      @user.update(organization_id: @organization.id)
      post "/listings", params: { classified_listing: {
        title: "Hey", category: "education", body_markdown: "hey hey my my", tag_list: "ruby, rails, go",
        post_as_organization: 1
      }}
      expect(ClassifiedListing.last.organization_id).to eq(@organization.id)
    end
  end

  describe "GETS /listings/edit" do
    before do
      @organization = create(:organization)
      @user = create(:user)
      @classified_listing = create(:classified_listing, user_id: @user.id)
      20.times do
        create(:credit, user_id: @user.id)
      end
      sign_in @user
    end
    it "has page content" do
      get "/listings/#{@classified_listing.id}/edit"
      expect(response.body).to include("You can bump your listing")
    end
  end


  describe "PUT /listings/:id" do
    before do
      @organization = create(:organization)
      @user = create(:user)
      @classified_listing = create(:classified_listing, user_id: @user.id)
      20.times do
        create(:credit, user_id: @user.id)
      end
      sign_in @user
    end
    it "updates bumped_at if action is bump" do
      # block = create(:block, user_id: user.id, input_css: ".blue { color: blue;}")
      put "/listings/#{@classified_listing.id}", params: {
        classified_listing: { action: "bump"}
      }
      expect(ClassifiedListing.last.bumped_at).to be > 10.seconds.ago
    end
    it "updates publish if action is unpublish" do
      put "/listings/#{@classified_listing.id}", params: {
        classified_listing: { action: "unpublish"}
      }
      expect(ClassifiedListing.last.published).to eq(false)
    end
    it "updates body_markdown" do
      put "/listings/#{@classified_listing.id}", params: {
        classified_listing: { body_markdown: "hello new markdown"}
      }
      expect(ClassifiedListing.last.body_markdown).to eq("hello new markdown")
    end
    it "does not update body_markdown if not bumped/created recently" do
      @classified_listing.update_column(:bumped_at, 50.hours.ago)
      put "/listings/#{@classified_listing.id}", params: {
        classified_listing: { body_markdown: "hello new markdown"}
      }
      expect(ClassifiedListing.last.body_markdown).not_to eq("hello new markdown")
    end
  end
end
