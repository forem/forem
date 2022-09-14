require "rails_helper"

RSpec.describe "/admin/advanced/response_templates", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /admin/advanced/response_templates" do
    it "renders with status 200" do
      get admin_response_templates_path
      expect(response).to have_http_status :ok
    end

    context "when there are response templates to render" do
      it "renders with status 200" do
        create(:response_template)
        get admin_response_templates_path
        expect(response).to have_http_status :ok
      end
    end

    context "when a single resource admin" do
      let(:single_resource_admin) { create(:user, :single_resource_admin, resource: ResponseTemplate) }

      it "renders with status 200" do
        sign_in single_resource_admin
        get admin_response_templates_path
        expect(response).to have_http_status :ok
      end
    end
  end

  describe "GET /admin/advanced/response_templates/new" do
    it "renders with status 200" do
      get admin_response_templates_path
      expect(response).to have_http_status :ok
    end
  end

  describe "POST /admin/advanced/response_templates" do
    it "successfully creates a response template" do
      post admin_response_templates_path, params: {
        response_template: {
          type_of: "mod_comment",
          content_type: "body_markdown",
          content: "nice job!",
          title: "something"
        }
      }
      expect(ResponseTemplate.count).to eq 1
    end

    it "shows a proper error message if the request was invalid" do
      post admin_response_templates_path, params: {
        response_template: {
          type_of: "mod_comment",
          content_type: "html",
          content: "nice job!",
          title: "something"
        }
      }
      expect(response.body).to include(I18n.t("models.response_template.comment_markdown"))
    end
  end

  describe "GET /admin/advanced/response_templates/:id/edit" do
    let(:response_template) { create(:response_template) }

    it "renders successfully if a valid response template was found" do
      get edit_admin_response_template_path(response_template.id)
      expect(response).to have_http_status(:ok)
    end

    it "renders the response template's attributes" do
      get edit_admin_response_template_path(response_template.id)

      expect(response.body).to include(
        CGI.escapeHTML(response_template.content),
        CGI.escapeHTML(response_template.title),
        response_template.content_type,
        response_template.type_of,
      )
    end
  end

  describe "PATCH /admin/advanced/response_templates/:id" do
    it "successfully updates with a valid request" do
      response_template = create(:response_template)
      new_title = generate(:title)
      patch admin_response_template_path(response_template.id), params: {
        response_template: {
          title: new_title
        }
      }
      expect(response_template.reload.title).to eq new_title
    end

    it "renders an error if the request was invalid" do
      response_template = create(:response_template)
      patch admin_response_template_path(response_template.id), params: {
        response_template: {
          content_type: "html"
        }
      }
      expect(response.body).to include(I18n.t("models.response_template.comment_markdown"))
    end
  end

  describe "DELETE /admin/advanced/response_templates/:id" do
    it "successfully deletes the response template" do
      response_template = create(:response_template)
      delete admin_response_template_path(response_template.id)
      expect { response_template.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
