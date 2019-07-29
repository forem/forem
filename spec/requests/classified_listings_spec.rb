require "rails_helper"

RSpec.describe "ClassifiedListings", type: :request do
  let(:user) { create(:user) }
  let(:listing_params) do
    {
      classified_listing: {
        title: "something",
        body_markdown: "something else",
        category: "cfp",
        tag_list: "",
        contact_via_connect: true
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
      let(:invalid_params) do
        {
          classified_listing: {
            title: "nothing",
            body_markdown: "",
            category: "cfp",
            tag_list: ""
          }
        }
      end

      it "renders errors with the listing" do
        post "/listings", params: invalid_params
        expect(response.body).to include("prohibited this listing from being saved")
      end

      it "does not subtract credits or create a listing if the listing is not valid" do
        expect do
          post "/listings", params: invalid_params
        end.to change(ClassifiedListing, :count).by(0).
          and change(user.credits.spent, :size).by(0)
      end
    end

    context "when the listing is valid" do
      it "redirects if the user does not have enough credits" do
        Credit.delete_all
        post "/listings", params: listing_params
        expect(response.body).to redirect_to("/credits")
      end

      it "redirects if the org does not have enough credits" do
        org_admin = create(:user, :org_admin)
        listing_params[:classified_listing][:post_as_organization] = "1"
        sign_in org_admin
        post "/listings", params: listing_params
        expect(response.body).to redirect_to("/credits")
      end

      it "redirects to /listings" do
        post "/listings", params: listing_params
        expect(response).to redirect_to "/listings"
      end

      it "properly deducts the amount of credits" do
        post "/listings", params: listing_params
        listing_cost = ClassifiedListing.categories_available[:cfp][:cost]
        expect(user.credits.spent.size).to eq(listing_cost)
      end

      it "creates a listing under the org" do
        org_admin = create(:user, :org_admin)
        org_id = org_admin.organizations.first.id
        Credit.create(organization_id: org_id)
        listing_params[:classified_listing][:organization_id] = org_id
        sign_in org_admin
        post "/listings", params: listing_params
        expect(ClassifiedListing.first.organization_id).to eq org_id
      end

      it "does not create a listing for an org not belonging to the user" do
        org = create(:organization)
        listing_params[:classified_listing][:organization_id] = org.id
        expect { post "/listings", params: listing_params }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "assigns the spent credits to the listing" do
        post "/listings", params: listing_params
        spent_credit = user.credits.spent.last
        expect(spent_credit.purchase_type).to eq("ClassifiedListing")
        expect(spent_credit.spent_at).not_to be_nil
      end

      it "does not create a listing or subtract credits if the purchase does not go through" do
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          post "/listings", params: listing_params
        end.to change(ClassifiedListing, :count).by(0).
          and change(user.credits.spent, :size).by(0)
      end
    end
  end

  describe "PUT /listings/:id" do
    let(:listing) { create(:classified_listing, user: user) }
    let(:organization) { create(:organization) }
    let(:org_listing) { create(:classified_listing, user: user, organization: organization) }

    before do
      sign_in user
    end

    context "when the bump action is called" do
      let(:params) { { classified_listing: { action: "bump" } } }

      it "does not bump the user listing and redirects to credits if the user has not enough credits" do
        previous_bumped_at = listing.bumped_at
        put "/listings/#{listing.id}", params: params
        expect(listing.reload.bumped_at.to_i).to eq(previous_bumped_at.to_i)
        expect(response.body).to redirect_to("/credits")
      end

      it "does not subtract spent credits if the user has not enough credits" do
        expect do
          put "/listings/#{listing.id}", params: params
        end.to change(user.credits.spent, :size).by(0)
      end

      it "does not bump the listing or subtract credits if the purchase does not go through" do
        previous_bumped_at = listing.bumped_at
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          put "/listings/#{listing.id}", params: params
        end.to change(user.credits.spent, :size).by(0)
        expect(listing.reload.bumped_at.to_i).to eq(previous_bumped_at.to_i)
      end

      it "bumps the listing and subtract credits" do
        cost = ClassifiedListing.cost_by_category(listing.category)
        create_list(:credit, cost, user: user)
        previous_bumped_at = listing.bumped_at
        expect do
          put "/listings/#{listing.id}", params: params
        end.to change(user.credits.spent, :size).by(cost)
        expect(listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end

      it "bumps the org listing using org credits before user credits" do
        cost = ClassifiedListing.cost_by_category(org_listing.category)
        create_list(:credit, cost, organization: organization)
        create_list(:credit, cost, user: user)
        previous_bumped_at = org_listing.bumped_at
        expect do
          put "/listings/#{org_listing.id}", params: params
        end.to change(organization.credits.spent, :size).by(cost)
        expect(org_listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end

      it "bumps the org listing using user credits if org credits insufficient and user credits are" do
        cost = ClassifiedListing.cost_by_category(org_listing.category)
        create_list(:credit, cost, user: user)
        previous_bumped_at = org_listing.bumped_at
        expect do
          put "/listings/#{org_listing.id}", params: params
        end.to change(user.credits.spent, :size).by(cost)
        expect(org_listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end
    end
  end
end
