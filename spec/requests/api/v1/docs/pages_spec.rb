require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "api/v1/pages" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let!(:existing_page) { create(:page) }
  let(:user) { api_secret.user }

  before do
    user.add_role(:admin)
  end

  path "/api/pages" do
    describe "get to view all pages" do
      get("show details for all pages") do
        security []
        tags "pages"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve details for all Page objects.
        DESCRIBE

        produces "application/json"

        response(200, "successful") do
          schema type: :array,
                 items: { "$ref": "#/components/schemas/Page" }
          add_examples

          run_test!
        end
      end
    end

    describe "create a new page" do
      post("pages") do
        tags "pages"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to create a new page.
        DESCRIBE

        produces "application/json"
        consumes "application/json"

        parameter name: :page, in: :body, schema: {
          type: :object,
          properties: {
            title: { type: :string, description: "Title of the page" },
            slug: { type: :string, description: "Used to link to this page in URLs, must be unique and URL-safe" },
            description: { type: :string, description: "For internal use, helps similar pages from one another" },
            body_markdown: { type: :string, description: "The text (in markdown) of the ad (required)" },
            body_json: { type: :string, description: "For JSON pages, the JSON body" },
            is_top_level_path: { type: :boolean,
                                 description: "If true, the page is available at '/{slug}' instead of '/page/{slug}', use with caution" },
            template: {
              type: :string, enum: Page::TEMPLATE_OPTIONS, default: "contained",
              description: "Controls what kind of layout the page is rendered in"
            }
          }
        }
        let(:page) do
          {
            title: "Example Page",
            slug: "example1",
            body_markdown: "# Hi, this is a New Page\nYep, it's an a new page",
            description: "a new page",
            template: template
          }
        end
        let(:template) { "contained" }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:template) { "moon" }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/pages/{id}" do
    describe "get to view a page" do
      get("show details for a page") do
        security []
        tags "pages"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve details for a single Page object, specified by ID.
        DESCRIBE

        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the page.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        let(:id) { existing_page.id }

        response(200, "successful") do
          schema "$ref": "#/components/schemas/Page"
          add_examples

          run_test!
        end
      end
    end

    describe "put to update a page" do
      put("update details for a page") do
        tags "pages"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve details for a single Page object, specified by ID.
        DESCRIBE

        produces "application/json"
        consumes "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the page.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1
        parameter name: :page,
                  in: :body,
                  description: "Representation of Page to be updated",
                  schema: { "$ref": "#/components/schemas/Page" }

        let(:id) { existing_page.id }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          let(:page) { attributes_for(:page, title: "New Title") }
          schema "$ref": "#/components/schemas/Page"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          let(:page) { attributes_for(:page, title: "Doesn't Matter") }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:page) { attributes_for(:page, template: "moon") }
          add_examples

          run_test!
        end
      end
    end

    describe "delete to destroy a page" do
      delete("remove a page") do
        tags "pages"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to delete a single Page object, specified by ID.
        DESCRIBE

        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the page.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        let(:id) { existing_page.id }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          schema "$ref": "#/components/schemas/Page"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }

          before do
            fake_page = instance_double(Page, destroy: false)
            allow(Page).to receive(:find).and_return(fake_page)
            allow(fake_page).to receive(:errors).and_return(double(full_messages: ["error"]))
          end

          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
