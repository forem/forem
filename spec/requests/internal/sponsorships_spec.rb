require "rails_helper"

RSpec.describe "/internal/sponsorships", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:org) { create(:organization, username: "super-community") }

  describe "GET /internal/sponsorships" do
    before do
      sign_in admin
      create(:sponsorship, organization: org, level: :gold)
    end

    it "renders successfully" do
      get "/internal/sponsorships"
      expect(response).to be_successful
    end

    it "shows sponsorship" do
      get "/internal/sponsorships"
      expect(response.body).to include(org.username)
      expect(response.body).to include("gold")
    end
  end

  describe "GET /internal/sponsorships/:id/edit" do
    let(:ruby) { create(:tag, name: "ruby") }
    let!(:sponsorship) { create(:sponsorship, organization: org, level: :tag, sponsorable: ruby, status: "pending", expires_at: Time.current) }

    before do
      sign_in admin
    end

    it "renders successfully" do
      get edit_internal_sponsorship_path(sponsorship.id)
      expect(response).to be_successful
    end
  end

  describe "PUT /internal/sponsorships/:id" do
    let(:ruby) { create(:tag, name: "ruby") }
    let!(:sponsorship) { create(:sponsorship, organization: org, level: :tag, sponsorable: ruby, status: "pending", expires_at: Time.current) }
    let(:valid_attributes) { { status: "live", expires_at: 1.month.from_now, blurb_html: Faker::Book.title } }
    let(:invalid_attributes) { { status: "super-live", expires_at: 1.month.from_now } }

    before do
      sign_in admin
    end

    it "redirects to index" do
      put "/internal/sponsorships/#{sponsorship.id}", params: { sponsorship: valid_attributes }
      expect(response).to redirect_to(internal_sponsorships_path)
    end

    it "updates the sponsorship" do
      put "/internal/sponsorships/#{sponsorship.id}", params: { sponsorship: valid_attributes }
      sponsorship.reload
      expect(sponsorship.status).to eq("live")
      expect(sponsorship.expires_at).to be > Time.current
      expect(sponsorship.blurb_html).to eq(valid_attributes[:blurb_html])
    end

    it "doesn't update when attributes are invalid" do
      put "/internal/sponsorships/#{sponsorship.id}", params: { sponsorship: invalid_attributes }
      sponsorship.reload
      expect(sponsorship.status).to eq("pending")
    end

    it "shows errors when attributes are invalid" do
      put "/internal/sponsorships/#{sponsorship.id}", params: { sponsorship: invalid_attributes }
      expect(response.body).to include("Status is not included in the list")
    end
  end

  describe "DELETE /internal/sponsorships/:id" do
    let!(:sponsorship) { create(:sponsorship, organization: org, level: :silver, status: "live", expires_at: Time.current) }

    it "destroys a sponsorship" do
      sign_in admin
      expect do
        delete internal_sponsorship_path(sponsorship.id)
      end.to change(Sponsorship, :count).by(-1)
    end
  end
end
