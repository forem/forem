require "rails_helper"

RSpec.describe "Api::V0::Listings" do
  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:api_secret_org) { create(:api_secret, :org_admin) }
  end

  shared_context "when param list is valid" do
    let(:listing_params) do
      {
        title: "Title",
        body_markdown: "Markdown text",
        category: "cfp",
        tags: [],
        contact_via_connect: true
      }
    end
    let(:draft_params) do
      {
        title: "Title draft",
        body_markdown: "Markdown draft text",
        category: "cfp",
        tags: [],
        contact_via_connect: true,
        action: "draft"
      }
    end
  end

  shared_context "when user has enough credit" do
    before do
      create_list(:credit, 25, user: user)
    end
  end

  shared_context "with 7 listings and 2 user" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      create_list(:classified_listing, 3, user: user1, category: "cfp")
      create_list(:classified_listing, 4, user: user2)
    end
  end

  describe "GET /api/listings" do
    include_context "with 7 listings and 2 user"

    it "returns json response and ok status" do
      get api_classified_listings_path
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "returns listings created" do
      get api_classified_listings_path
      expect(response.parsed_body.size).to eq(7)
      expect(response.parsed_body.first["type_of"]).to eq("classified_listing")
      expect(response.parsed_body.first["slug"]).to eq(ClassifiedListing.last.slug)
      expect(response.parsed_body.first["user"]).to include("username")
      expect(response.parsed_body.first["user"]["username"]).not_to be_empty
    end

    it "supports pagination" do
      get api_classified_listings_path, params: { page: 2, per_page: 2 }
      expect(response.parsed_body.length).to eq(2)
      get api_classified_listings_path, params: { page: 4, per_page: 2 }
      expect(response.parsed_body.length).to eq(1)
    end
  end

  describe "GET /api/listings/category/:category" do
    include_context "with 7 listings and 2 user"

    it "displays only listings from the cfp category" do
      get api_classified_listings_category_path("cfp")
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end
  end

  describe "GET /api/listings/:id" do
    include_context "with 7 listings and 2 user"
    let(:listing) { ClassifiedListing.where(category: "cfp").last }

    it "displays a unique listing" do
      get api_classified_listing_path(listing.id)

      expect(response).to have_http_status(:ok)

      expect(response.parsed_body["type_of"]).to eq("classified_listing")
      expect(response.parsed_body["slug"]).to eq(listing.slug)
      expect(response.parsed_body["user"]).to include("username")
      expect(response.parsed_body["user"]["username"]).not_to be_empty
    end
  end

  describe "POST /api/listings" do
    def post_classified_listing(key: api_secret.secret, **params)
      headers = { "api-key" => key, "content-type" => "application/json" }
      post api_classified_listings_path, params: { classified_listing: params }.to_json, headers: headers
    end

    def user_admin_organization(user)
      org = create(:organization)
      create(:organization_membership, user_id: user.id, organization_id: org.id, type_of_user: "admin")
      org
    end

    describe "user cannot proceed if not properly unauthorizedœ" do
      let(:api_secret) { create(:api_secret) }

      it "fails with no api key" do
        post api_classified_listings_path, headers: { "content-type" => "application/json" }
        expect(response). to have_http_status(:unauthorized)
      end

      it "fails with the wrong api key" do
        post api_classified_listings_path, headers: { "api-key" => "foobar", "content-type" => "application/json" }
        expect(response). to have_http_status(:unauthorized)
      end
    end

    describe "user must have enough credit to create a classified listing" do
      include_context "when user is authorized"

      it "fails to create a classified listing if user does not have enough credit" do
        post_classified_listing(category: "cfp")
        expect(response).to have_http_status(:payment_required)
      end

      it "fails to create a classifiedlisting if the org does not have enough credit" do
        org = user_admin_organization(user)
        post_classified_listing(category: "cfp", organization_id: org.id)
        expect(response).to have_http_status(:payment_required)
      end
    end

    describe "user cannot create a classified with a request lacking mandatory parameters" do
      let(:invalid_params) { { title: "Title", category: "cfp" } }

      include_context "when user is authorized"
      include_context "when user has enough credit"

      it "fails if no params are given" do
        post_classified_listing
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails if a mandatory param is missing" do
        post_classified_listing(invalid_params)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not subtract credits or create a listing if the listing is not valid" do
        expect do
          post_classified_listing(invalid_params)
        end.to change(ClassifiedListing, :count).by(0).and change(user.credits.spent, :size).by(0)
      end
    end

    describe "user creates classified listings" do
      include_context "when user is authorized"
      include_context "when param list is valid"
      include_context "when user has enough credit"

      it "properly deducts the amount of credits" do
        post_classified_listing(listing_params)
        listing_cost = ClassifiedListing.categories_available[:cfp][:cost]
        expect(user.credits.spent.size).to eq(listing_cost)
      end

      it "creates a listing draft under the org" do
        org_admin = api_secret_org.user
        org_id = org_admin.organizations.first.id
        Credit.create(organization_id: org_id)
        post_classified_listing(key: api_secret_org.secret, **draft_params.merge(organization_id: org_id))
        expect(ClassifiedListing.first.organization_id).to eq org_id
      end

      it "creates a listing under the org" do
        org = user_admin_organization(user)
        Credit.create(organization_id: org.id)
        post_classified_listing(listing_params.merge(organization_id: org.id))
        expect(ClassifiedListing.first.organization_id).to eq org.id
      end

      it "does not create a listing draft for an org not belonging to the user" do
        org = create(:organization)
        expect { post_classified_listing(draft_params.merge(organization_id: org.id)) }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "does not create a listing for an org not belonging to the user" do
        org = create(:organization)
        expect { post_classified_listing(listing_params.merge(organization_id: org.id)) }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "assigns the spent credits to the listing" do
        post_classified_listing(listing_params)
        spent_credit = user.credits.spent.last
        expect(spent_credit.purchase_type).to eq("ClassifiedListing")
        expect(spent_credit.spent_at).not_to be_nil
      end

      it "cannot create a draft due to internal error" do
        listing = create(:classified_listing, user_id: user.id)
        allow(ClassifiedListing).to receive_messages(cost_by_category: nil, new: listing)
        allow(Organization).to receive(:find_by)
        allow(listing).to receive(:save) do
          listing.errors.add(:base)
          false
        end
        post_classified_listing(draft_params)
        expect(response.parsed_body["errors"]["base"]).to eq(["is invalid"])
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "creates listing draft and does not subtract credits" do
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          post_classified_listing(draft_params)
        end.to change(ClassifiedListing, :count).by(1).
          and change(user.credits.spent, :size).by(0)
      end

      it "does not create a listing or subtract credits if the purchase does not go through" do
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          post_classified_listing(listing_params)
        end.to change(ClassifiedListing, :count).by(0).
          and change(user.credits.spent, :size).by(0)
      end

      it "creates a classified listing belonging to the user" do
        expect do
          post_classified_listing(listing_params)
          expect(response).to have_http_status(:created)
        end.to change(ClassifiedListing, :count).by(1)
        expect(ClassifiedListing.find(response.parsed_body["id"]).user).to eq(user)
      end

      it "creates a classified listing with a title, a body markdown, a category" do
        expect do
          post_classified_listing(listing_params)
          expect(response).to have_http_status(:created)
        end.to change(ClassifiedListing, :count).by(1)
        expect(ClassifiedListing.find(response.parsed_body["id"]).title).to eq("Title")
        expect(ClassifiedListing.find(response.parsed_body["id"]).body_markdown).to eq("Markdown text")
        expect(ClassifiedListing.find(response.parsed_body["id"]).category).to eq("cfp")
      end

      it "creates a classified listing with a location" do
        params = listing_params.merge(location: "Frejus")
        expect do
          post_classified_listing(params)
          expect(response).to have_http_status(:created)
        end.to change(ClassifiedListing, :count).by(1)
        expect(ClassifiedListing.find(response.parsed_body["id"]).location).to eq("Frejus")
      end

      it "creates a classified listing with a list of tags and a contact" do
        params = listing_params.merge(tags: %w[discuss javascript], contact_via_connect: true)
        expect do
          post_classified_listing(params)
          expect(response).to have_http_status(:created)
        end.to change(ClassifiedListing, :count).by(1)
        expect(ClassifiedListing.find(response.parsed_body["id"]).cached_tag_list).to eq("discuss, javascript")
        expect(ClassifiedListing.find(response.parsed_body["id"]).contact_via_connect).to eq(true)
      end
    end

    describe "with oauth token" do
      include_context "when param list is valid"

      it "fails with oauth token" do
        user = create(:user)
        access_token = create(:doorkeeper_access_token, resource_owner_id: user.id)
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        post api_classified_listings_path, params: { classified_listing: listing_params }.to_json, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /api/listings/:id" do
    def put_classified_listing(id, **params)
      headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
      put api_classified_listing_path(id), params: { classified_listing: params }.to_json, headers: headers
    end

    let(:user) { create(:user) }
    let(:another_user) { create(:user) }
    let(:listing) { create(:classified_listing, user_id: user.id) }
    let(:another_user_listing) { create(:classified_listing, user_id: another_user.id) }
    let(:listing_draft) { create(:classified_listing, user: user) }
    let(:organization) { create(:organization) }
    let(:org_listing) { create(:classified_listing, user: user, organization: organization) }
    let(:org_listing_draft) { create(:classified_listing, user: user, organization: organization) }

    before do
      listing_draft.update_columns(bumped_at: nil, published: false)
      org_listing_draft.update_columns(bumped_at: nil, published: false)
    end

    describe "user cannot proceed if not properly unauthorizedœ" do
      let(:api_secret) { create(:api_secret) }

      it "fails with no api key" do
        put api_classified_listing_path(listing.id), headers: { "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with the wrong api key" do
        put api_classified_listing_path(listing.id), headers: { "api-key" => "foobar", "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorized user has no credit" do
      include_context "when user is authorized"

      it "fails to bump a classified listing" do
        previous_bumped_at = listing.bumped_at
        put_classified_listing(listing.id, action: "bump")
        expect(response).to have_http_status(:payment_required)
        expect(listing.reload.bumped_at.to_i).to eq(previous_bumped_at.to_i)
      end

      it "does not subtract spent credits if the user has not enough credits" do
        expect do
          put_classified_listing(listing.id, action: "bump")
        end.to change(user.credits.spent, :size).by(0)
      end
    end

    context "when the bump action is called" do
      include_context "when user is authorized"
      include_context "when user has enough credit"

      let(:params) { { classified_listing: { action: "bump" } } }

      it "does not bump the listing or subtract credits if the purchase does not go through" do
        previous_bumped_at = listing.bumped_at
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          put_classified_listing(listing.id, action: "bump")
        end.to change(user.credits.spent, :size).by(0)
        expect(listing.reload.bumped_at.to_i).to eq(previous_bumped_at.to_i)
      end

      it "bumps the listing and subtract credits" do
        cost = ClassifiedListing.cost_by_category(listing.category)
        create_list(:credit, cost, user: user)
        previous_bumped_at = listing.bumped_at
        expect do
          put_classified_listing(listing.id, action: "bump")
        end.to change(user.credits.spent, :size).by(cost)
        expect(listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end

      it "bumps the org listing using org credits before user credits" do
        cost = ClassifiedListing.cost_by_category(org_listing.category)
        create_list(:credit, cost, organization: organization)
        create_list(:credit, cost, user: user)
        previous_bumped_at = org_listing.bumped_at
        expect do
          put_classified_listing(org_listing.id, action: "bump")
        end.to change(organization.credits.spent, :size).by(cost)
        expect(org_listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end

      it "bumps the org listing using user credits if org credits insufficient and user credits are" do
        cost = ClassifiedListing.cost_by_category(org_listing.category)
        create_list(:credit, cost, user: user)
        previous_bumped_at = org_listing.bumped_at
        expect do
          put_classified_listing(org_listing.id, action: "bump")
        end.to change(user.credits.spent, :size).by(cost)
        expect(org_listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end
    end

    context "when the publish action is called" do
      include_context "when user is authorized"

      it "publishes a draft and charges user credits if first publish" do
        cost = ClassifiedListing.cost_by_category(listing_draft.category)
        create_list(:credit, cost, user: user)
        expect do
          put_classified_listing(listing_draft.id, action: "publish")
        end.to change(user.credits.spent, :size).by(cost)
      end

      it "publishes a draft and ensures published column is true" do
        cost = ClassifiedListing.cost_by_category(listing_draft.category)
        create_list(:credit, cost, user: user)
        put_classified_listing(listing_draft.id, action: "publish")
        expect(listing_draft.reload.published).to eq(true)
      end

      it "publishes an org draft and charges org credits if first publish" do
        cost = ClassifiedListing.cost_by_category(org_listing_draft.category)
        create_list(:credit, cost, organization: organization)
        expect do
          put_classified_listing(org_listing_draft.id, action: "publish")
        end.to change(organization.credits.spent, :size).by(cost)
      end

      it "publishes an org draft and ensures published column is true" do
        cost = ClassifiedListing.cost_by_category(org_listing_draft.category)
        create_list(:credit, cost, organization: organization)
        put_classified_listing(org_listing_draft.id, action: "publish")
        expect(org_listing_draft.reload.published).to eq(true)
      end

      it "publishes a draft that was charged and is within 30 days of bump doesn't charge credits" do
        listing.update_column(:published, false)
        expect do
          put_classified_listing(listing.id, action: "publish")
        end.to change(user.credits.spent, :size).by(0)
      end

      it "publishes a draft that was charged and is within 30 days of bump and successfully sets published as true" do
        listing.update_column(:published, false)
        put_classified_listing(listing.id, action: "publish")
        expect(listing.reload.published).to eq(true)
      end
    end

    context "when the publish action is called without credit" do
      include_context "when user is authorized"

      it "fails to publish draft and doesn't charge credits" do
        expect do
          put_classified_listing(listing_draft.id, action: "publish")
        end.to change(user.credits.spent, :size).by(0)
      end

      it "fails to publish draft and published remains false" do
        put_classified_listing(listing_draft.id, action: "publish")
        expect(listing_draft.reload.published).to eq(false)
      end
    end

    context "when user is authorized and has credit to update one of his listing" do
      include_context "when user is authorized"
      include_context "when user has enough credit"

      it "returns HTTP 422 if no params given" do
        put_classified_listing(listing.id)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "updates the title of his listing" do
        put_classified_listing(listing.id, title: "This is a new title")
        expect(response).to have_http_status(:ok)
        expect(listing.reload.title).to eq "This is a new title"
      end

      it "updates the tags" do
        put_classified_listing(listing.id, tags: %w[golang api])
        expect(response).to have_http_status(:ok)
        expect(listing.reload.cached_tag_list).to eq "golang, api"
      end

      it "unpublishes the listing" do
        expect do
          put_classified_listing(listing.id, action: "unpublish")
          listing.reload
        end.to change(listing, :published).from(true).to(false)
        expect(response).to have_http_status(:ok)
      end

      it "cannot update another user listing" do
        expect do
          put_classified_listing(another_user_listing.id, title: "Test for a new title")
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
