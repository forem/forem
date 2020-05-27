require "rails_helper"

RSpec.describe "/internal/growth", type: :request do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    xit "blocks the request" do
      expect do
        get "/internal/welcome"
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before do
      sign_in super_admin
      get "/internal/welcome"
    end

    xit "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Welcome) }

    before do
      sign_in single_resource_admin
      get "/internal/welcome"
    end

    xit "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before do
      sign_in single_resource_admin
    end

    xit "blocks the request" do
      expect do
        get "/internal/welcome"
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
