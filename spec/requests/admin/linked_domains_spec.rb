require "rails_helper"

RSpec.describe "Admin::LinkedDomains", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let!(:linked_domain) { LinkedDomain.create!(host: "example.com", net_score: 500) }

  describe "GET /admin/moderation/linked_domains" do
    context "when signed in as a tech admin" do
      before do
        sign_in admin
        get admin_linked_domains_path
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "displays the linked domains" do
        expect(response.body).to include("example.com")
        expect(response.body).to include("500")
      end
    end

    context "when signed in as a regular user" do
      before do
        sign_in user
      end

      it "raises NotAuthorizedError" do
        expect { get admin_linked_domains_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/moderation/linked_domains/:id/edit" do
    context "when signed in as a tech admin" do
      before do
        sign_in admin
        get edit_admin_linked_domain_path(linked_domain)
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "displays the edit form" do
        expect(response.body).to include("Edit Linked Domain: example.com")
      end
    end
  end

  describe "PATCH /admin/moderation/linked_domains/:id" do
    context "when signed in as a tech admin" do
      before do
        sign_in admin
      end

      it "updates the manual setting and redirects" do
        patch admin_linked_domain_path(linked_domain), params: {
          linked_domain: { manual_setting: "ignored" }
        }

        expect(response).to redirect_to(admin_linked_domains_path)
        expect(linked_domain.reload.ignored?).to be true
        expect(linked_domain.net_score).to eq(0)
      end
    end

    context "when signed in as a regular user" do
      before do
        sign_in user
      end

      it "raises NotAuthorizedError and does not update" do
        expect {
          patch admin_linked_domain_path(linked_domain), params: {
            linked_domain: { manual_setting: "ignored" }
          }
        }.to raise_error(Pundit::NotAuthorizedError)

        expect(linked_domain.reload.not_set?).to be true
      end
    end
  end
end
