require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "api/v1/billboards" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:billboard) { create(:billboard) }
  let(:user) { api_secret.user }

  before { user.add_role(:admin) }

  path "/api/billboards" do
    describe "GET /billboards" do
      get("Billboards") do
        tags "billboards"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a list of all billboards.
        DESCRIBE

        produces "application/json"

        response(200, "successful") do
          schema type: :array,
                 items: { "$ref": "#/components/schemas/DisplayAd" }
          let(:"api-key") { api_secret.secret }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end
      end
    end

    describe "POST /billboards" do
      post "Create a billboard" do
        tags "billboards"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to create a new billboard.
        DESCRIBE

        produces "application/json"
        consumes "application/json"
        parameter name: :billboard, in: :body, schema: { type: :object,
                                                         items: { "$ref": "#/components/schemas/DisplayAd" } }

        let(:billboard) do
          {
            body_markdown: "# Hi, this is ad\nYep, it's an ad",
            name: "Example Billboard",
            display_to: "all",
            approved: true,
            published: true,
            placement_area: placement_area,
            target_geolocations: "US-WA, CA-BC"
          }
        end

        let(:placement_area) { "post_comments" }

        response "201", "A billboard" do
          schema  type: :object,
                  items: { "$ref": "#/components/schemas/DisplayAd" }
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
          let(:placement_area) { "moon" }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/billboards/{id}" do
    describe "GET /billboards/:id" do
      get "A billboard (by id)" do
        tags "billboards"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a single billboard, via its id.
        DESCRIBE

        produces "application/json"
        parameter name: :id,
                  in: :path,
                  required: true,
                  description: "The ID of the billboard.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 123

        response(200, "successful") do
          let(:id) { billboard.id }
          let(:"api-key") { api_secret.secret }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end

        response "404", "Unknown Billboard ID" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end
      end
    end

    describe "PUT /billboards/:id" do
      put "Update a billboard by ID" do
        tags "billboards"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to update the attributes of a single billboard, via its id.
        DESCRIBE

        produces "application/json"
        consumes "application/json"

        parameter name: :id,
                  in: :path,
                  required: true,
                  description: "The ID of the billboard.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 123

        parameter name: :billboard, in: :body, schema: { type: :object,
                                                         items: { "$ref": "#/components/schemas/DisplayAd" } }

        let(:placement_area) { "post_comments" }

        response(200, "successful") do
          schema  type: :object,
                  items: { "$ref": "#/components/schemas/DisplayAd" }
          let(:"api-key") { api_secret.secret }
          let(:id) { billboard.id }
          add_examples

          run_test!
        end

        response(404, "not found") do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          let(:id) { billboard.id }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/billboards/{id}/unpublish" do
    describe "PUT /billboards/:id/unpublish" do
      put "Unpublish a billboard" do
        tags "billboards"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to remove a billboard from rotation by un-publishing it.
        DESCRIBE

        produces "application/json"

        parameter name: :id,
                  in: :path,
                  required: true,
                  description: "The ID of the billboard to unpublish.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 123

        response(204, "no content") do
          let(:"api-key") { api_secret.secret }
          let(:id) { billboard.id }
          add_examples

          run_test!
        end

        response(404, "not found") do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          let(:id) { billboard.id }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
