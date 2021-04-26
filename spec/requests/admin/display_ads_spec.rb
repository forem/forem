require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe Rails.application.routes.url_helpers.admin_display_ads_path.to_s, type: :request do
  let(:get_resource) { get admin_display_ads_path }
  let(:org) { create(:organization) }
  let(:params) do
    { organization_id: org.id, body_markdown: "[Click here!](https://example.com)", placement_area: "sidebar_left",
      approved: true, published: true }
  end
  let(:post_resource) { post admin_display_ads_path, params: params }

  it_behaves_like "an InternalPolicy dependant request", DisplayAd do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      it "creates a new display_ad" do
        expect do
          post_resource
        end.to change { DisplayAd.all.count }.by(1)
      end

      it "busts sidebar" do
        allow(EdgeCache::BustSidebar).to receive(:call)
        post_resource
        expect(EdgeCache::BustSidebar).to have_received(:call).once
      end
    end

    describe "PUT #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      let!(:display_ad) { create(:display_ad, approved: false) }

      it "updates DisplayAd's approved value" do
        Timecop.freeze(Time.current) do
          expect do
            put "/admin/display_ads/#{display_ad.id}", params: params
          end.to change { display_ad.reload.approved }.from(false).to(true)
        end
      end
    end

    describe "DELETE /admin/display_ads/:id" do
      let!(:display_ad) { create(:display_ad) }

      it "deletes the Display Ad" do
        expect do
          delete admin_display_ad_path(display_ad.id)
        end.to change { DisplayAd.all.count }.by(-1)
        expect(response.body).to redirect_to admin_display_ads_path
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: DisplayAd) }

    before { sign_in single_resource_admin }

    describe "GET #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      it "creates a new display_ad" do
        expect do
          post_resource
        end.to change { DisplayAd.all.count }.by(1)
      end
    end

    describe "PUT #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      let!(:display_ad) { create(:display_ad, approved: false) }

      it "updates DisplayAd's approved value" do
        Timecop.freeze(Time.current) do
          expect do
            put admin_display_ad_path(display_ad.id), params: params
          end.to change { display_ad.reload.approved }.from(false).to(true)
        end
      end
    end

    describe "DELETE /admin/display_ads/:id" do
      let!(:display_ad) { create(:display_ad) }

      it "deletes the Display Ad" do
        expect do
          delete admin_display_ad_path(display_ad.id)
        end.to change { DisplayAd.all.count }.by(-1)
        expect(response.body).to redirect_to admin_display_ads_path
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before { sign_in single_resource_admin }

    describe "GET #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST #{Rails.application.routes.url_helpers.admin_display_ads_path}" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
