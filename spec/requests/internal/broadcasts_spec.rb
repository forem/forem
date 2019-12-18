require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/internal/Broadcasts", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Broadcast do
    let(:request) { get "/internal/broadcasts" }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get "/internal/broadcasts"
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before do
      sign_in super_admin
      get "/internal/broadcasts"
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Broadcast) }

    before do
      sign_in single_resource_admin
      get "/internal/broadcasts"
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before do
      sign_in single_resource_admin
    end

    it "blocks the request" do
      expect do
        get "/internal/broadcasts"
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
