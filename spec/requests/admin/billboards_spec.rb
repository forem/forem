require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/customization/billboards" do
  let(:get_resource) { get admin_billboards_path }
  let(:org) { create(:organization) }
  let(:geolocations) { "US-NY, US-ME, CA-ON" }
  let(:params) do
    { organization_id: org.id, body_markdown: "[Click here!](https://example.com)",
      target_geolocations: geolocations, placement_area: "sidebar_left",
      approved: true, published: true, priority: true }
  end
  let(:post_resource) { post admin_billboards_path, params: params }

  it_behaves_like "an InternalPolicy dependant request", Billboard do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/customization/billboards" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/customization/billboards" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET /admin/customization/billboards" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/customization/billboards/:id/edit" do
      let!(:billboard) { create(:billboard) }

      it "allows the request" do
        get edit_admin_billboard_path(billboard.id)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/customization/billboards/:id" do
      let!(:billboard) { create(:billboard) }

      it "allows the request" do
        get admin_billboard_path(billboard.id)
        expect(response).to have_http_status(:ok)
      end

      it "lists clicks but not impressions or partner impressions" do
        reader = create(:user)
        %w[click impression partner_impression].each do |category|
          create(:billboard_event, billboard: billboard, user: reader, category: category)
        end

        get admin_billboard_path(billboard.id)

        expect(response.body).to include("<strong>click</strong> by @#{reader.username}")
        expect(response.body).not_to include("<strong>impression</strong>")
        expect(response.body).not_to include("<strong>partner_impression</strong>")
      end
    end

    describe "POST /admin/customization/billboards" do
      it "creates a new billboard and sets creator to current_user", :aggregate_failures do
        expect do
          post_resource
        end.to change(Billboard, :count).by(1)
        expect(Billboard.last.creator_id).to eq(super_admin.id)
      end

      it "fails to create a new billboard with invalid target geolocations" do
        expect do
          post admin_billboards_path, params: params.merge(target_geolocations: "US-UM, CA-UH")
        end.not_to change(Billboard, :count)
      end

      it "creates a new billboard with no target geolocations" do
        expect do
          post admin_billboards_path, params: params.merge(target_geolocations: nil)
        end.to change(Billboard, :count).by(1)
      end

      it "creates a new billboard with special_behavior and minimized_body_markdown", :aggregate_failures do
        expect do
          post admin_billboards_path,
               params: params.merge(special_behavior: "persistent", minimized_body_markdown: "Minimized content")
        end.to change(Billboard, :count).by(1)
        expect(Billboard.last.special_behavior).to eq("persistent")
        expect(Billboard.last.minimized_body_markdown).to eq("Minimized content")
        expect(Billboard.last.minimized_processed_html).to include("Minimized content")
      end
    end

    describe "PUT /admin/customization/billboards" do
      let!(:billboard) { create(:billboard, approved: false) }

      it "updates Billboard's approved and priority values and redirects back to edit path", :aggregate_failures do
        Timecop.freeze(Time.current) do
          put admin_billboard_path(billboard.id), params: params
          billboard.reload
          expect(billboard.approved).to be(true)
          expect(billboard.priority).to be(true)
          expect(response.body).to redirect_to edit_admin_billboard_path(billboard.id)
        end
      end

      it "updates special_behavior and minimized_body_markdown", :aggregate_failures do
        put admin_billboard_path(billboard.id),
            params: params.merge(special_behavior: "persistent", minimized_body_markdown: "Updated minimized content")
        expect(billboard.reload.special_behavior).to eq("persistent")
        expect(billboard.minimized_body_markdown).to eq("Updated minimized content")
        expect(billboard.minimized_processed_html).to include("Updated minimized content")
      end
    end

    describe "DELETE /admin/billboards/:id" do
      let!(:billboard) { create(:billboard) }

      it "deletes the Billboard" do
        expect do
          delete admin_billboard_path(billboard.id)
        end.to change(Billboard, :count).by(-1)
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Billboard) }

    before { sign_in single_resource_admin }

    describe "GET /admin/customization/billboards" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/customization/billboards" do
      it "creates a new billboard and sets creator to current_user", :aggregate_failures do
        expect do
          post_resource
        end.to change(Billboard, :count).by(1)
        expect(Billboard.last.creator_id).to eq(single_resource_admin.id)
      end
    end

    describe "PUT /admin/customization/billboards" do
      let!(:billboard) { create(:billboard, approved: false) }

      it "updates Billboard's approved value" do
        Timecop.freeze(Time.current) do
          expect do
            put admin_billboard_path(billboard.id), params: params
          end.to change { billboard.reload.approved }.from(false).to(true)
        end
      end
    end

    describe "DELETE /admin/billboards/:id" do
      let!(:billboard) { create(:billboard) }

      it "deletes the Billboard" do
        expect do
          delete admin_billboard_path(billboard.id)
        end.to change(Billboard, :count).by(-1)
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before { sign_in single_resource_admin }

    describe "GET /admin/customization/billboards" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/customization/billboards" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
