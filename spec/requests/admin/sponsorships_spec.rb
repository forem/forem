require "rails_helper"

RSpec.describe "/admin/sponsorships", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:org) { create(:organization, username: "super-community") }

  describe "GET /admin/sponsorships" do
    before do
      sign_in admin
      create(:sponsorship, organization: org, level: :gold)
    end

    it "renders successfully" do
      get "/admin/sponsorships"
      expect(response).to be_successful
    end

    it "shows sponsorship" do
      get "/admin/sponsorships"
      expect(response.body).to include(org.username)
      expect(response.body).to include("gold")
    end
  end

  describe "GET /admin/sponsorships/:id/edit" do
    let(:ruby) { build_stubbed(:tag, name: "ruby") }
    let!(:sponsorship) do
      create(:sponsorship, organization: org, level: :tag, sponsorable: ruby, status: "pending",
                           expires_at: Time.current)
    end

    before do
      sign_in admin
    end

    it "renders successfully" do
      get edit_admin_sponsorship_path(sponsorship.id)
      expect(response).to be_successful
    end
  end

  describe "PUT /admin/sponsorships/:id" do
    let(:ruby) { build_stubbed(:tag, name: "ruby") }
    let!(:sponsorship) do
      create(:sponsorship, organization: org, level: :tag, sponsorable: ruby, status: "pending",
                           expires_at: Time.current)
    end
    let(:valid_attributes) { { status: "live", expires_at: 1.month.from_now, blurb_html: Faker::Book.title } }
    let(:invalid_attributes) { { status: "super-live", expires_at: 1.month.from_now } }

    before do
      sign_in admin
    end

    it "redirects to index" do
      put "/admin/sponsorships/#{sponsorship.id}", params: { sponsorship: valid_attributes }
      expect(response).to redirect_to(admin_sponsorships_path)
    end

    it "updates the sponsorship" do
      put "/admin/sponsorships/#{sponsorship.id}", params: { sponsorship: valid_attributes }
      sponsorship.reload
      expect(sponsorship.status).to eq("live")
      expect(sponsorship.expires_at).to be > Time.current
      expect(sponsorship.blurb_html).to eq(valid_attributes[:blurb_html])
    end

    it "doesn't update when attributes are invalid" do
      put "/admin/sponsorships/#{sponsorship.id}", params: { sponsorship: invalid_attributes }
      sponsorship.reload
      expect(sponsorship.status).to eq("pending")
    end

    it "shows errors when attributes are invalid" do
      put "/admin/sponsorships/#{sponsorship.id}", params: { sponsorship: invalid_attributes }
      expect(response.body).to include("Status is not included in the list")
    end
  end

  describe "DELETE /admin/sponsorships/:id" do
    let!(:sponsorship) do
      create(:sponsorship, organization: org, level: :silver, status: "live", expires_at: Time.current)
    end

    it "destroys a sponsorship" do
      sign_in admin
      expect do
        delete admin_sponsorship_path(sponsorship.id)
      end.to change(Sponsorship, :count).by(-1)
    end
  end
end
