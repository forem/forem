require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup

RSpec.describe "Api::V1::Docs::OpenAPI" do
  path "/api/v1/openapi.json" do
    get "OpenAPI description" do
      tags "openapi"
      security []
      description "Retrieve the machine-readable OpenAPI contract for this Forem instance.

Automated clients should use this document instead of inferring endpoint schemas from responses or errors."
      operationId "getOpenAPIDescription"
      produces "application/json"

      response "200", "The OpenAPI description" do
        schema type: :object,
               required: %w[openapi info paths],
               properties: {
                 openapi: { type: :string },
                 info: { type: :object },
                 paths: { type: :object }
               }

        run_test!
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
