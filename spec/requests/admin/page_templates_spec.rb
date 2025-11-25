require "rails_helper"

RSpec.describe "/admin/customization/page_templates" do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in admin
  end

  describe "GET /admin/customization/page_templates" do
    it "responds with 200 OK" do
      get admin_page_templates_path
      expect(response).to have_http_status(:ok)
    end

    it "displays page templates" do
      template = create(:page_template, name: "Test Template")
      get admin_page_templates_path
      expect(response.body).to include("Test Template")
    end
  end

  describe "GET /admin/customization/page_templates/:id" do
    it "displays the page template details" do
      template = create(:page_template, name: "Test Template", description: "A test description")
      get admin_page_template_path(template)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Template")
      expect(response.body).to include("A test description")
    end

    it "shows pages using this template" do
      template = create(:page_template, name: "Test Template")
      page = create(:page, title: "Test Page", page_template: template, template_data: { "title" => "Hello" })

      get admin_page_template_path(template)
      expect(response.body).to include("Test Page")
    end
  end

  describe "GET /admin/customization/page_templates/new" do
    it "displays the new template form" do
      get new_admin_page_template_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Page Template")
    end

    it "prefills fields when forking a template" do
      original = create(:page_template, name: "Original Template")
      get new_admin_page_template_path(fork_from: original.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fork Template")
      expect(response.body).to include("Original Template (Fork)")
    end
  end

  describe "POST /admin/customization/page_templates" do
    it "creates a new page template" do
      template_params = {
        page_template: {
          name: "New Template",
          description: "A new template",
          body_markdown: "# Hello {{name}}",
          template_type: "contained",
          field_names: ["name"],
          field_types: ["text"],
          field_labels: ["Your Name"],
          field_required: ["1"],
        },
      }

      expect do
        post admin_page_templates_path, params: template_params
      end.to change(PageTemplate, :count).by(1)

      expect(response).to redirect_to(admin_page_templates_path)
      template = PageTemplate.last
      expect(template.name).to eq("New Template")
      expect(template.schema_fields.first["name"]).to eq("name")
    end

    it "displays errors for invalid input" do
      template_params = {
        page_template: {
          name: "",
          template_type: "contained",
        },
      }

      post admin_page_templates_path, params: template_params
      expect(response.body).to include("can&#39;t be blank")
    end
  end

  describe "GET /admin/customization/page_templates/:id/edit" do
    it "displays the edit form" do
      template = create(:page_template, name: "Editable Template")
      get edit_admin_page_template_path(template)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Editable Template")
    end
  end

  describe "PATCH /admin/customization/page_templates/:id" do
    it "updates the page template" do
      template = create(:page_template, name: "Original Name")

      patch admin_page_template_path(template), params: {
        page_template: { name: "Updated Name" },
      }

      expect(response).to redirect_to(admin_page_templates_path)
      expect(template.reload.name).to eq("Updated Name")
    end
  end

  describe "DELETE /admin/customization/page_templates/:id" do
    it "deletes the page template" do
      template = create(:page_template)

      expect do
        delete admin_page_template_path(template)
      end.to change(PageTemplate, :count).by(-1)

      expect(response).to redirect_to(admin_page_templates_path)
    end

    it "prevents deletion when pages exist" do
      template = create(:page_template)
      create(:page, page_template: template, template_data: { "title" => "Hello" })

      expect do
        delete admin_page_template_path(template)
      end.not_to change(PageTemplate, :count)

      expect(response).to redirect_to(admin_page_templates_path)
      expect(flash[:error]).to include("Cannot delete")
    end
  end

  describe "creating pages from templates" do
    it "links to create a page from template in the index" do
      template = create(:page_template, name: "Test Template")
      get admin_page_templates_path

      expect(response.body).to include(new_admin_page_path(page_template_id: template.id))
    end

    it "prefills the new page form with template fields" do
      template = create(:page_template,
                        name: "Test Template",
                        data_schema: {
                          "fields" => [
                            { "name" => "author", "type" => "text", "label" => "Author Name", "required" => true },
                          ]
                        })

      get new_admin_page_path(page_template_id: template.id)
      expect(response.body).to include("Using template:")
      expect(response.body).to include("Author Name")
    end

    it "shows template fields when forking a template-based page" do
      template = create(:page_template,
                        name: "Team Member Template",
                        data_schema: {
                          "fields" => [
                            { "name" => "member_name", "type" => "text", "label" => "Member Name", "required" => true },
                          ]
                        })

      original_page = create(:page,
                             title: "John Doe",
                             slug: "team-john",
                             page_template: template,
                             template_data: { "member_name" => "John Doe" })

      get new_admin_page_path(page: original_page.id)

      expect(response.body).to include("Forking")
      expect(response.body).to include("team-john")
      expect(response.body).to include("Team Member Template")
      expect(response.body).to include("Member Name")
      expect(response.body).to include("John Doe") # The template data should be prefilled
    end
  end
end

