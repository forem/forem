require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/internal/broadcasts", type: :request do
  let(:get_resource) { get "/internal/broadcasts" }
  let(:params) { { title: "Hello!", processed_html: "<pHello!</p>", type_of: "Onboarding", sent: true } }
  let(:post_resource) { post "/internal/broadcasts", params: params }

  it_behaves_like "an InternalPolicy dependant request", Broadcast do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /internal/broadcasts" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /internal/broadcasts" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET /internal/broadcasts" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /internal/broadcasts" do
      it "creates a new broadcast" do
        expect do
          post_resource
        end.to change { Broadcast.all.count }.by(1)
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Broadcast) }

    before { sign_in single_resource_admin }

    describe "GET /internal/broadcasts" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /internal/broadcasts" do
      it "creates a new broadcast" do
        expect do
          post_resource
        end.to change { Broadcast.all.count }.by(1)
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before { sign_in single_resource_admin }

    describe "GET /internal/broadcasts" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /internal/broadcasts" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
