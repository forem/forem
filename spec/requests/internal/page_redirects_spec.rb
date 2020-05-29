require "rails_helper"

RSpec.describe "/internal/page_redirects", type: :request do
  context "when the user is not an admin" do
    it "blocks the request" do
      user = create(:user)
      sign_in user

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

    before { sign_in admin }

    describe "GET /internal/page_redirects" do
      it "renders with status 200" do
        get internal_page_redirects_path
        expect(response.status).to eq 200
      end
    end

    describe "GET /internal/page_redirects/new" do
      it "renders with status 200" do
        get new_internal_page_redirect_path
        expect(response.status).to eq 200
      end
    end

    describe "POST /internal/page_redirects" do
      it "successfully creates a page redirect" do
        post internal_page_redirects_path, params: {
          page_redirect: {
            old_slug: "/nice-old-slug",
            new_slug: "/nice-new-slug"
          }
        }
        expect(PageRedirect.count).to eq 1
      end

      it "shows a proper error message if the request was invalid" do
        post internal_page_redirects_path, params: {
          page_redirect: {
            old_slug: page_redirect.old_slug,
            new_slug: "/nice-new-slug"
          }
        }
        expect(response.body).to include("Old slug has already been taken")
      end

      it "sets source to admin" do
        old_slug = "/nice-old-slug"
        post internal_page_redirects_path, params: {
          page_redirect: {
            old_slug: old_slug,
            new_slug: "/nice-new-slug"
          }
        }

        page_redirect = PageRedirect.find_by(old_slug: old_slug)
        expect(page_redirect.source).to eq "admin"
      end
    end

    describe "GET /internal/page_redirects/:id/edit" do
      let(:page_redirect) { create(:page_redirect) }

      it "renders successfully if a valid page redirect was found" do
        get edit_internal_page_redirect_path(page_redirect.id)
        expect(response).to have_http_status(:ok)
      end

      it "renders the page redirect's attributes" do
        get edit_internal_page_redirect_path(page_redirect.id)

        expect(response.body).to include(
          page_redirect.old_slug,
          page_redirect.new_slug,
        )
      end
    end

    describe "PATCH /internal/page_redirects/:id" do
      it "successfully updates with a valid request" do
        page_redirect = create(:page_redirect)
        new_slug = "/a-shiny-new-slug"
        patch internal_page_redirect_path(page_redirect.id), params: {
          page_redirect: {
            old_slug: page_redirect.old_slug,
            new_slug: new_slug
          }
        }
        expect(page_redirect.reload.new_slug).to eq new_slug
      end

      it "renders an error if the request was invalid" do
        patch internal_page_redirect_path(page_redirect.id), params: {
          page_redirect: {
            new_slug: ""
          }
        }
        expect(response.body).to include(CGI.escapeHTML("New slug can't be blank"))
      end

      it "doesn't update old_slug" do
        updated_old_slug = "/an-updated-old-slug"
        patch internal_page_redirect_path(page_redirect.id), params: {
          page_redirect: {
            old_slug: updated_old_slug
          }
        }

        expect(page_redirect.old_slug).not_to eq updated_old_slug
      end

      it "sets source to admin" do
        page_redirect = create(:page_redirect)
        patch internal_page_redirect_path(page_redirect.id), params: {
          page_redirect: {
            old_slug: page_redirect.old_slug,
            new_slug: "/nice-new-slug"
          }
        }

        expect(page_redirect.reload.source).to eq "admin"
      end
    end

    describe "DELETE /internal/page_redirects/:id" do
      it "successfully deletes the page redirect" do
        page_redirect = create(:page_redirect)
        delete internal_page_redirect_path(page_redirect.id)
        expect { page_redirect.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
