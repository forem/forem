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
    let(:user) { create(:user, :without_profile, profile_image: nil) }

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
    let(:super_admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }

    before { sign_in super_admin }

    describe "GET /admin/customization/billboards" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end

      it "uses without_count pagination and selects only summary columns", :aggregate_failures do
        create(:billboard, name: "Target Billboard", body_markdown: "Heavy markdown payload", organization: nil)

        queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
          next if payload[:name] == "SCHEMA" || payload[:cached]

          queries << payload[:sql]
        end
        get admin_billboards_path, params: { search: "Target" }
        ActiveSupport::Notifications.unsubscribe(subscriber)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Target Billboard")
        count_queries = queries.grep(/SELECT COUNT\(\*\) FROM "display_ads"/i)
        expect(count_queries).to be_empty

        select_query = queries.detect { |sql| sql.include?('FROM "display_ads"') }
        expect(select_query).to be_present
        expect(select_query).not_to include("body_markdown")
        expect(select_query).not_to include('"display_ads"."processed_html"')
      end

      it "renders previous link on subsequent pages", :aggregate_failures do
        create_list(:billboard, 2, organization: nil)

        get admin_billboards_path, params: { page: 2, search: "Ad" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('rel="prev"')
      end
    end

    describe "GET /admin/customization/billboards/:id/edit" do
      let!(:billboard) { create(:billboard, organization: nil) }

      it "allows the request" do
        get edit_admin_billboard_path(billboard.id)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/customization/billboards/:id" do
      let!(:billboard) { create(:billboard, organization: nil) }

      it "allows the request" do
        get admin_billboard_path(billboard.id)
        expect(response).to have_http_status(:ok)
      end

      it "bounds billboard events to the recent 30-day window and preloads event users", :aggregate_failures do
        recent_user_one = create(:user, :without_profile, profile_image: nil)
        recent_user_two = create(:user, :without_profile, profile_image: nil)
        stale_user = create(:user, :without_profile, profile_image: nil)
        create(:billboard_event, billboard: billboard, user: recent_user_one, category: "click", created_at: 2.days.ago)
        create(:billboard_event, billboard: billboard, user: recent_user_two, category: "click", created_at: 3.days.ago)
        create(:billboard_event, billboard: billboard, user: stale_user, category: "click", created_at: 45.days.ago)

        preload_queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
          next if payload[:name] == "SCHEMA" || payload[:cached]

          if payload[:sql].include?('SELECT "users"."id", "users"."username" FROM "users"')
            preload_queries << payload[:sql]
          end
        end
        get admin_billboard_path(billboard.id)
        ActiveSupport::Notifications.unsubscribe(subscriber)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("@#{recent_user_one.username}")
        expect(response.body).to include("@#{recent_user_two.username}")
        expect(response.body).not_to include("@#{stale_user.username}")
        expect(preload_queries.size).to eq(1)
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
      let!(:billboard) { create(:billboard, approved: false, organization: nil) }

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
      let!(:billboard) { create(:billboard, organization: nil) }

      it "deletes the Billboard" do
        expect do
          delete admin_billboard_path(billboard.id)
        end.to change(Billboard, :count).by(-1)
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) do
      create(:user, :single_resource_admin, :without_profile, profile_image: nil, resource: Billboard)
    end

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
      let!(:billboard) { create(:billboard, approved: false, organization: nil) }

      it "updates Billboard's approved value" do
        Timecop.freeze(Time.current) do
          expect do
            put admin_billboard_path(billboard.id), params: params
          end.to change { billboard.reload.approved }.from(false).to(true)
        end
      end
    end

    describe "DELETE /admin/billboards/:id" do
      let!(:billboard) { create(:billboard, organization: nil) }

      it "deletes the Billboard" do
        expect do
          delete admin_billboard_path(billboard.id)
        end.to change(Billboard, :count).by(-1)
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) do
      create(:user, :single_resource_admin, :without_profile, profile_image: nil, resource: Article)
    end

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
