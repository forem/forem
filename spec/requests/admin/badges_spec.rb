require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/badges", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let!(:badge) { create(:badge, title: "Not 'Hello, world!'") }
  let(:params) do
    {
      badge: {
        title: "Hello, world!",
        slug: "greeting-badge",
        description: "Awarded to welcoming users",
        credits_awarded: 10,
        badge_image: Rack::Test::UploadedFile.new("spec/support/fixtures/images/image1.jpeg", "image/jpeg")
      }
    }
  end

  it_behaves_like "an InternalPolicy dependant request", Badge do
    let(:request) { get "/admin/badges" }
  end

  describe "POST /admin/badges" do
    let(:post_resource) { post "/admin/badges", params: params }

    before { sign_in admin }

    it "successfully creates a badge" do
      expect do
        post_resource
      end.to change { Badge.all.count }.by(1)
    end
  end

  describe "PUT /admin/badges" do
    before { sign_in admin }

    it "successfully updates the badge" do
      expect do
        patch "/admin/badges/#{badge.id}", params: params
      end.to change { badge.reload.title }.to("Hello, world!")
    end

    it "successfully updates badge's credits_awarded" do
      expect do
        patch "/admin/badges/#{badge.id}", params: params
      end.to change { badge.reload.credits_awarded }.to(10)
    end
  end
end
