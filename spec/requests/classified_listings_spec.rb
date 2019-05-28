require "rails_helper"

RSpec.describe "ClassifiedListings", type: :request do
  let(:user) { create(:user) }
  let(:valid_listing_params) do
    {
      classified_listing: {
        title: "something",
        body_markdown: "something else",
        category: "cfp",
        tag_list: "",
        post_as_organization: "0"
      }
    }
  end

  before do
    sign_in user
    create_list(:credit, 25, user: user)
  end

  describe "POST /listings" do
    context "when the listing is invalid" do
      it "renders errors with the listing" do
        post "/listings", params: {
          classified_listing: {
            title: "nothing",
            body_markdown: "",
            category: "cfp",
            tag_list: "",
            post_as_organization: "0"
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
        Credit.create(organization_id: org_admin.organization_id)
        valid_listing_params[:classified_listing][:post_as_organization] = "1"
        sign_in org_admin
        post "/listings", params: valid_listing_params
        expect(ClassifiedListing.first.organization_id).to eq org_admin.organization_id
      end
    end
  end
end
