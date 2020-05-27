require "rails_helper"

RSpec.describe "/internal/page_redirects", type: :request do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get internal_page_redirects_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) do
      create(:user, :single_resource_admin, resource: PageRedirect)
    end

    it "renders the page" do
      sign_in single_resource_admin

      get internal_page_redirects_path
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is an admin" do
    let(:admin) { create(:user, :admin) }
    let(:page_redirect) { create(:page_redirect) }

    before do
      page_redirect
      sign_in admin
    end

    it "does not block the request" do
      get internal_page_redirects_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the page with a page redirect" do
      get internal_page_redirects_path

      expect(response.body).to include(page_redirect.old_slug)
      expect(response.body).to include(page_redirect.new_slug)
      expect(response.body).to include(page_redirect.id.to_s)
    end

    it "searches by new_slug" do
      new_slug_page_redirect = create(:page_redirect, new_slug: "/new-test")

      get internal_page_redirects_path(search: new_slug_page_redirect.new_slug)

      expect(response.body).not_to include(page_redirect.old_slug)
      expect(response.body).not_to include(page_redirect.new_slug)

      expect(response.body).to include(new_slug_page_redirect.old_slug)
      expect(response.body).to include(new_slug_page_redirect.new_slug)
    end

    it "searches by old_slug" do
      old_slug_page_redirect = create(:page_redirect, old_slug: "/old-test")

      get internal_page_redirects_path(search: old_slug_page_redirect.old_slug)

      expect(response.body).not_to include(page_redirect.old_slug)
      expect(response.body).not_to include(page_redirect.new_slug)

      expect(response.body).to include(old_slug_page_redirect.old_slug)
      expect(response.body).to include(old_slug_page_redirect.new_slug)
    end
  end
end
