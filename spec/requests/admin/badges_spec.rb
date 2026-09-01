require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/content_manager/badge_achievements" do
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
    let(:request) { get admin_badges_path }
  end

  describe "POST /admin/content_manager/badge_achievements" do
    let(:post_resource) { post admin_badges_path, params: params }

    before { sign_in admin }

    it "successfully creates a badge with explicit slug" do
      expect do
        post_resource
      end.to change(Badge, :count).by(1)
      expect(Badge.last.slug).to eq("greeting-badge")
    end

    it "auto-generates slug when not provided" do
      params[:badge][:title] = "Hello World"
      params[:badge].delete(:slug)
      expect do
        post admin_badges_path, params: params
      end.to change(Badge, :count).by(1)
      expect(Badge.last.slug).to eq("hello-world")
    end
  end

  describe "PUT /admin/content_manager/badge_achievements" do
    before { sign_in admin }

    it "successfully updates the badge title and explicit slug" do
      expect do
        patch admin_badge_path(badge.id), params: params
      end.to change { badge.reload.title }.to("Hello, world!")
      expect(badge.slug).to eq("greeting-badge")
    end

    it "preserves slug when only title is changed" do
      original_slug = badge.slug
      patch admin_badge_path(badge.id), params: { badge: { title: "Only Title Changed", slug: badge.slug } }
      expect(badge.reload.title).to eq("Only Title Changed")
      expect(badge.slug).to eq(original_slug)
    end

    it "successfully updates badge's credits_awarded" do
      expect do
        patch admin_badge_path(badge.id), params: params
      end.to change { badge.reload.credits_awarded }.to(10)
    end
  end
end
