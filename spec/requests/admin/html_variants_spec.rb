require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/customization/html_variants", type: :request do
  let(:get_resource) { get admin_html_variants_path }
  let(:params) do
    { name: "Banner", html: "<h1>Hello HTML Variants!</h1>", group: "campaign",
      approved: true, published: true }
  end
  let(:post_resource) { post admin_html_variants_path, params: params }

  it_behaves_like "an InternalPolicy dependant request", HtmlVariant do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/customization/html_variants" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/customization/html_variants" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET /admin/customization/html_variants" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/customization/html_variants" do
      it "creates a new html_variant" do
        expect do
          post_resource
        end.to change { HtmlVariant.all.count }.by(1)
      end
    end

    describe "PUT /admin/customization/html_variants" do
      let!(:html_variant) { create(:html_variant, approved: false) }

      it "updates HtmlVariant's approved value" do
        Timecop.freeze(Time.current) do
          expect do
            put admin_html_variant_path(html_variant.id), params: params
          end.to change { html_variant.reload.approved }.from(false).to(true)
        end
      end
    end

    describe "DELETE /admin/customization/html_variants/:id" do
      let!(:html_variant) { create(:html_variant) }

      it "deletes the Display Ad" do
        expect do
          delete admin_html_variant_path(html_variant.id)
        end.to change { HtmlVariant.all.count }.by(-1)
        expect(response.body).to redirect_to admin_html_variants_path
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: HtmlVariant) }

    before { sign_in single_resource_admin }

    describe "GET /admin/customization/html_variants" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/customization/html_variants" do
      it "creates a new html_variant" do
        expect do
          post_resource
        end.to change { HtmlVariant.all.count }.by(1)
      end
    end

    describe "PUT /admin/customization/html_variants" do
      let!(:html_variant) { create(:html_variant, approved: false) }

      it "updates HtmlVariant's approved value" do
        Timecop.freeze(Time.current) do
          expect do
            put admin_html_variant_path(html_variant.id), params: params
          end.to change { html_variant.reload.approved }.from(false).to(true)
        end
      end
    end

    describe "DELETE /admin/customization/html_variants/:id" do
      let!(:html_variant) { create(:html_variant) }

      it "deletes the Display Ad" do
        expect do
          delete admin_html_variant_path(html_variant.id)
        end.to change { HtmlVariant.all.count }.by(-1)
        expect(response.body).to redirect_to admin_html_variants_path
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before { sign_in single_resource_admin }

    describe "GET /admin/customization/html_variants" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/customization/html_variants" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
