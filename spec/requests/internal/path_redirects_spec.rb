require "rails_helper"

RSpec.describe "/internal/path_redirects", type: :request do
  context "when the user is not an admin" do
    it "blocks the request" do
      user = create(:user)
      sign_in user

      expect do
        get internal_path_redirects_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) do
      create(:user, :single_resource_admin, resource: PathRedirect)
    end

    it "renders the page" do
      sign_in single_resource_admin

      get internal_path_redirects_path
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is an admin" do
    let(:admin) { create(:user, :admin) }
    let(:path_redirect) { create(:path_redirect) }

    before { sign_in admin }

    describe "GET /internal/path_redirects" do
      it "renders with status 200" do
        get internal_path_redirects_path
        expect(response.status).to eq 200
      end
    end

    describe "GET /internal/path_redirects/new" do
      it "renders with status 200" do
        get new_internal_path_redirect_path
        expect(response.status).to eq 200
      end
    end

    describe "POST /internal/path_redirects" do
      it "successfully creates a path redirect" do
        post internal_path_redirects_path, params: {
          path_redirect: {
            old_path: "/nice-old-path",
            new_path: "/nice-new-path"
          }
        }
        expect(PathRedirect.count).to eq 1
      end

      it "shows a proper error message if the request was invalid" do
        post internal_path_redirects_path, params: {
          path_redirect: {
            old_path: path_redirect.old_path,
            new_path: "/nice-new-path"
          }
        }
        expect(response.body).to include("Old path has already been taken")
      end

      it "sets source to admin" do
        old_path = "/nice-old-path"
        post internal_path_redirects_path, params: {
          path_redirect: {
            old_path: old_path,
            new_path: "/nice-new-path"
          }
        }

        path_redirect = PathRedirect.find_by(old_path: old_path)
        expect(path_redirect.source).to eq "admin"
      end
    end

    describe "GET /internal/path_redirects/:id/edit" do
      let(:path_redirect) { create(:path_redirect) }

      it "renders successfully if a valid path redirect was found" do
        get edit_internal_path_redirect_path(path_redirect.id)
        expect(response).to have_http_status(:ok)
      end

      it "renders the path redirect's attributes" do
        get edit_internal_path_redirect_path(path_redirect.id)

        expect(response.body).to include(
          path_redirect.old_path,
          path_redirect.new_path,
        )
      end
    end

    describe "PATCH /internal/path_redirects/:id" do
      it "successfully updates with a valid request" do
        path_redirect = create(:path_redirect)
        new_path = "/a-shiny-new-path"
        patch internal_path_redirect_path(path_redirect.id), params: {
          path_redirect: {
            old_path: path_redirect.old_path,
            new_path: new_path
          }
        }
        expect(path_redirect.reload.new_path).to eq new_path
      end

      it "renders an error if the request was invalid" do
        patch internal_path_redirect_path(path_redirect.id), params: {
          path_redirect: {
            new_path: ""
          }
        }
        expect(response.body).to include(CGI.escapeHTML("New path can't be blank"))
      end

      it "doesn't update old_path" do
        updated_old_path = "/an-updated-old-path"
        patch internal_path_redirect_path(path_redirect.id), params: {
          path_redirect: {
            old_path: updated_old_path
          }
        }

        expect(path_redirect.old_path).not_to eq updated_old_path
      end

      it "sets source to admin" do
        path_redirect = create(:path_redirect)
        patch internal_path_redirect_path(path_redirect.id), params: {
          path_redirect: {
            old_path: path_redirect.old_path,
            new_path: "/nice-new-path"
          }
        }

        expect(path_redirect.reload.source).to eq "admin"
      end
    end

    describe "DELETE /internal/path_redirects/:id" do
      it "successfully deletes the path redirect" do
        path_redirect = create(:path_redirect)
        delete internal_path_redirect_path(path_redirect.id)
        expect { path_redirect.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
