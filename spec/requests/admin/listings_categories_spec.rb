require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/app/listings/categories", type: :request do
  let(:get_resource) { get admin_listing_categories_path }
  let(:params) do
    { name: "Computer stuff", cost: 22, rules: "Things computers do",
      slug: "computer", social_preview_color: "#000", social_preview_description: "Computer things" }
  end
  let(:post_resource) { post admin_listing_categories_path, params: params }

  it_behaves_like "an InternalPolicy dependant request", ListingCategory do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/app/listings/categories" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/app/listings/categories" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET /admin/app/listings/categories" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/app/listings/categories" do
      it "creates a new listing_category" do
        expect do
          post_resource
        end.to change { ListingCategory.all.count }.by(1)
      end
    end

    describe "PUT /admin/app/listings/categories" do
      let!(:listing_category) { create(:listing_category, name: "Computers") }

      it "updates Listing Category name" do
        Timecop.freeze(Time.current) do
          expect do
            put admin_listing_category_path(listing_category.id), params: params
          end.to change { listing_category.reload.name }.from("Computers").to("Computer stuff")
        end
      end
    end

    describe "DELETE /admin/app/listings/categories/:id" do
      let!(:listing_category) { create(:listing_category) }

      it "deletes the Listing Category" do
        expect do
          delete admin_listing_category_path(listing_category.id)
        end.to change { ListingCategory.all.count }.by(-1)
        expect(response.body).to redirect_to admin_listing_categories_path
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: ListingCategory) }

    before { sign_in single_resource_admin }

    describe "GET /admin/app/listings/categories" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/app/listings/categories" do
      it "creates a new listing_category" do
        expect do
          post_resource
        end.to change { ListingCategory.all.count }.by(1)
      end
    end

    describe "PUT /admin/app/listings/categories" do
      let!(:listing_category) { create(:listing_category, name: "Computers") }

      it "updates Listing Category name" do
        Timecop.freeze(Time.current) do
          expect do
            put admin_listing_category_path(listing_category.id), params: params
          end.to change { listing_category.reload.name }.from("Computers").to("Computer stuff")
        end
      end
    end

    describe "DELETE /admin/listings/categories/:id" do
      let!(:listing_category) { create(:listing_category) }

      it "deletes the Listing Category" do
        expect do
          delete admin_listing_category_path(listing_category.id)
        end.to change { ListingCategory.all.count }.by(-1)
        expect(response.body).to redirect_to admin_listing_categories_path
      end
    end
  end
end
