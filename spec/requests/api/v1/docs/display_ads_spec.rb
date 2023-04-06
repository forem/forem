require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "api/v1/display_ads" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:display_ad) { create(:display_ad) }
  let(:user) { api_secret.user }

  before { user.add_role(:admin) }

  path "/api/display_ads" do
    describe "get all display ads" do
      get("display ads") do
        tags "display ads"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a list of all display ads.
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

    describe "create a new display ad" do
      post("display ads") do
        tags "display ads"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to create a new display ad.
        DESCRIBE

        produces "application/json"
        consumes "application/json"
        parameter name: :display_ad, in: :body, schema: { type: :object,
                                                          items: { "$ref": "#/components/schemas/DisplayAd" } }

        let(:display_ad) do
          {
            body_markdown: "# Hi, this is ad\nYep, it's an ad",
            name: "Example Ad",
            display_to: "all",
            approved: true,
            published: true,
            placement_area: placement_area
          }
        end

        let(:placement_area) { "post_comments" }

        response(200, "successful") do
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

  path "/api/display_ads/{id}" do
    describe "GET a single display ad" do
      get("display ad") do
        tags "display ads"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a single display ad, via its id.
        DESCRIBE

        produces "application/json"
        parameter name: :id,
                  in: :path,
                  required: true,
                  description: "The ID of the display ad.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 123

        response(200, "successful") do
          let(:id) { display_ad.id }
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

        response "404", "Unknown DisplayAd ID" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end
      end
    end

    describe "PUT update an ad" do
      put("display ads") do
        tags "display ads"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to update the attributes of a single display ad, via its id.
        DESCRIBE

        produces "application/json"
        consumes "application/json"

        parameter name: :id,
                  in: :path,
                  required: true,
                  description: "The ID of the display ad.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 123

        parameter name: :display_ad, in: :body, schema: { type: :object,
                                                          items: { "$ref": "#/components/schemas/DisplayAd" } }

        let(:placement_area) { "post_comments" }

        response(200, "successful") do
          schema  type: :object,
                  items: { "$ref": "#/components/schemas/DisplayAd" }
          let(:"api-key") { api_secret.secret }
          let(:id) { display_ad.id }
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
          let(:id) { display_ad.id }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/display_ads/{id}/unpublish" do
    describe "PUT to unpublish an ad" do
      put("unpublish") do
        tags "display ads"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to remove a display ad from rotation by un-publishing it.
        DESCRIBE

        produces "application/json"

        parameter name: :id,
                  in: :path,
                  required: true,
                  description: "The ID of the display ad to unpublish.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 123

        response(204, "no content") do
          let(:"api-key") { api_secret.secret }
          let(:id) { display_ad.id }
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
          let(:id) { display_ad.id }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
