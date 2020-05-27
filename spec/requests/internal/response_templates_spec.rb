require "rails_helper"

RSpec.describe "/internal/response_templates", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /internal/response_templates" do
    xit "renders with status 200" do
      get internal_response_templates_path
      expect(response.status).to eq 200
    end

    context "when there are response templates to render" do
      xit "renders with status 200" do
        create(:response_template)
        get internal_response_templates_path
        expect(response.status).to eq 200
      end
    end

    context "when a single resource admin" do
      let(:single_resource_admin) { create(:user, :single_resource_admin, resource: ResponseTemplate) }

      xit "renders with status 200" do
        sign_in single_resource_admin
        get internal_response_templates_path
        expect(response.status).to eq 200
      end
    end
  end

  describe "GET /internal/response_templates/new" do
    xit "renders with status 200" do
      get internal_response_templates_path
      expect(response.status).to eq 200
    end
  end

  describe "POST /internal/response_templates" do
    xit "successfully creates a response template" do
      post internal_response_templates_path, params: {
        response_template: {
          type_of: "mod_comment",
          content_type: "body_markdown",
          content: "nice job!",
          title: "something"
        }
      }
      expect(ResponseTemplate.count).to eq 1
    end

    xit "shows a proper error message if the request was invalid" do
      post internal_response_templates_path, params: {
        response_template: {
          type_of: "mod_comment",
          content_type: "html",
          content: "nice job!",
          title: "something"
        }
      }
      expect(response.body).to include(ResponseTemplate::COMMENT_VALIDATION_MSG)
    end
  end

  describe "GET /internal/response_templates/:id/edit" do
    let(:response_template) { create(:response_template) }

    xit "renders successfully if a valid response template was found" do
      get edit_internal_response_template_path(response_template.id)
      expect(response).to have_http_status(:ok)
    end

    xit "renders the response template's attributes" do
      get edit_internal_response_template_path(response_template.id)

      expect(response.body).to include(
        CGI.escapeHTML(response_template.content),
        CGI.escapeHTML(response_template.title),
        response_template.content_type,
        response_template.type_of,
      )
    end
  end

  describe "PATCH /internal/response_templates/:id" do
    xit "successfully updates with a valid request" do
      response_template = create(:response_template)
      new_title = generate(:title)
      patch internal_response_template_path(response_template.id), params: {
        response_template: {
          title: new_title
        }
      }
      expect(response_template.reload.title).to eq new_title
    end

    xit "renders an error if the request was invalid" do
      response_template = create(:response_template)
      patch internal_response_template_path(response_template.id), params: {
        response_template: {
          content_type: "html"
        }
      }
      expect(response.body).to include(ResponseTemplate::COMMENT_VALIDATION_MSG)
    end
  end

  describe "DELETE /internal/response_templates/:id" do
    xit "successfully deletes the response template" do
      response_template = create(:response_template)
      delete internal_response_template_path(response_template.id)
      expect { response_template.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
