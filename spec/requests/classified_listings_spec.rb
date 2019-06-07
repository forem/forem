require "rails_helper"

RSpec.describe "ClassifiedListings", type: :request do
  let(:user) { create(:user) }
  let(:valid_listing_params) do
    {
      classified_listing: {
        title: "something",
        body_markdown: "something else",
        category: "cfp",
        tag_list: ""
      }
    }
  end

  describe "GET /listings/new" do
    before { sign_in user }

    context "when the user has no credits" do
      it "shows the proper messages" do
        get "/listings/new"
        expect(response.body).to include "Listings Require Credits"
        expect(response.body).to include "You need at least one credit to create a listing."
      end
    end

    context "when the user has credits" do
      it "shows the number of credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "You have #{random_number} credits available"
      end
    end

    context "when the user has no credits and belongs to an organization" do
      let(:organization) { create(:organization) }

      before { create(:organization_membership, user_id: user.id, organization_id: organization.id) }

      it "shows the proper message when both user and org have no credits" do
        get "/listings/new"
        expect(response.body).to include "Listings Require Credits"
      end

      it "shows the number of credits of the user if the user has credits but the org has no credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "You have #{random_number} credits available"
      end

      it "shows the number of credits of the organization if the org has credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, organization: organization)
        get "/listings/new"
        expect(response.body).to include "has <span id=\"org-credits-number\">#{random_number}</span> credits"
      end

      it "shows the number of credits of both the user and the organization if they both have credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, organization: organization)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "has <span id=\"org-credits-number\">#{random_number}</span> credits"
        expect(response.body).to include "You have #{random_number} credits available"
      end
    end
  end

  describe "POST /listings" do
    before do
      sign_in user
      create_list(:credit, 25, user: user)
    end

    context "when the listing is invalid" do
      it "renders errors with the listing" do
        post "/listings", params: {
          classified_listing: {
            title: "nothing",
            body_markdown: "",
            category: "cfp",
            tag_list: ""
          }
        }
        expect(response.body).to include("prohibited this listing from being saved")
      end

      it "redirects if the user does not have enough credits" do
        Credit.delete_all
        post "/listings", params: valid_listing_params
        expect(response.body).to redirect_to("/credits")
      end

      it "redirects if the org does not have enough credits" do
        org_admin = create(:user, :org_admin)
        valid_listing_params[:classified_listing][:post_as_organization] = "1"
        sign_in org_admin
        post "/listings", params: valid_listing_params
        expect(response.body).to redirect_to("/credits")
      end
    end

    context "when the listing is valid" do
      it "redirects to /listings" do
        post "/listings", params: valid_listing_params
        expect(response).to redirect_to "/listings"
      end

      it "properly deducts the amount of credits" do
        post "/listings", params: valid_listing_params
        expect(user.credits.where(spent: false).size).to eq 24
      end

      it "creates a listing under the org" do
        org_admin = create(:user, :org_admin)
        org_id = org_admin.organizations.first.id
        Credit.create(organization_id: org_id)
        valid_listing_params[:classified_listing][:organization_id] = org_id
        sign_in org_admin
        post "/listings", params: valid_listing_params
        expect(ClassifiedListing.first.organization_id).to eq org_id
      end
    end
  end
end
